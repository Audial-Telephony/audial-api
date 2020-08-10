require 'time'

class StatusNotificationWorker
	include SuckerPunch::Job
	workers 1

	def perform
		logger.info "Status Notification Worker Running...."

		while true do
			logger.info "Waiting for notifications"
			# retrieve data from  notification queues
	      queue, payload = redis.blpop( 'enigma:notifications:agents', 'enigma:notifications:campaigns', 'enigma:notifications:cdrs' )

	      logger.info "Got a #{queue} notification"
	      type, request_type, notif  = parse_payload_data(queue, payload)
	   
          # FIXME: This should be logged at DEBUG, but leaving at INFO while we troubleshoot
          logger.info "REQUEST TYPE: #{type}/#{request_type} with data #{notif.inspect}"

	      case type
	      when :campaigns
	      	if request_type.eql?(:queue_calls) 
	      		queue_calls(notif)
	      	elsif request_type.eql?(:status)
	      		update_campaign(notif)
	      	end	      			
	      when :agents
	      	update_agent(notif)
	      when :cdrs
	      	handle_cdr(notif)
	      end

	    end
	end

	def redis
		begin
		    @redis ||= Redis.new(:url => ENV['NOTIF_REDIS_URL'])
		    @redis.ping
		rescue Redis::BaseConnectionError => error
			logger.warn "Status Notification Worker: #{error}, retrying in 1s"
			sleep(1)
			retry
		end
		@redis
	end

	def parse_payload_data(queue, payload)
		json_data = JSON.parse(payload)
		json_data.symbolize_keys!

		type = queue.split(':').last
		sub_type = json_data.delete :type
		notif = json_data.delete :payload

		return type.to_sym, sub_type.to_sym, notif.symbolize_keys!
	end

	def handle_cdr(payload)
		logger.info "StatusNotificationWorker - handle_cdr - payload #{payload.to_s}"
		EndedCallNotificationWorker.perform_async(payload)
	end

	def queue_calls(json_data)
		CampaignWorker.perform_async(json_data[:ref], json_data[:rate].to_i)
	end

	def update_agent(json_data)
		# Update the agent state without casing it to fire callbacks to the after_save method
    # FIXME: Why?
    agent = Agent[extension: json_data[:ref]]
    unless agent
      logger.error "Requested to update Agent #{json_data[:ref]}, but agent not found! - #{json_data.inspect}"
      return
    end
		agent.this.update({status: json_data[:status]})
	end

	def update_campaign(json_data)
    campaign = Campaign[ref: json_data[:ref]]
    unless campaign
      logger.error "Requested to update Campaign #{json_data[:ref]}, but campaign not found! - #{json_data.inspect}"
      return
    end
		campaign.update(status: json_data[:status])
		# TODO: On shutdown we need to remove all calls from the queue and set them back to pending
	end

	def logger
		SuckerPunch.logger
	end

end
