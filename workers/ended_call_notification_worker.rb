require 'time'

class EndedCallNotificationWorker
	include SuckerPunch::Job

	# Consume notifications
	def perform(payload)
		logger.info "CDR Notification Worker Running...."
		notif  = parse_payload_data(payload)
		update_records notif
	end

	def redis
		begin
				@redis ||= Redis.new(:url => ENV['NOTIF_REDIS_URL'])
		    @redis.ping
		rescue Redis::BaseConnectionError => error
			logger.warn "Ended Call Notification Worker: #{error}, retrying in 1s"
			sleep(1)
			retry
		end
		@redis
	end

	def find_cdr!(cdr_id)
        cdr = CDR[id: cdr_id]
        unless cdr
          logger.warn "Could not find a CDR with reference #{cdr_id}. Disregarding notification."
          raise Error, "CDR [#{cdr_id}] not found"
        end
        cdr
    end

	def parse_payload_data(notif)
		notif[:dialed_at] = (notif[:dialed_at]) ? Time.parse(notif[:dialed_at]) : 0
		notif[:callee_answered_at] = (notif[:callee_answered_at]) ? Time.parse(notif[:callee_answered_at]) : 0
		notif[:agent_answered_at] = (notif[:agent_answered_at]) ? Time.parse(notif[:agent_answered_at]) : 0
		notif[:ended_at] = (notif[:ended_at]) ? Time.parse(notif[:ended_at]) : 0

		return notif
	end

	def update_records(notif)
		cdr = find_cdr!(notif[:call_ref])
		agent = Agent[extension: notif[:agent]]

		callee_data = {last_dialed_at: Time.at(notif[:dialed_at].to_i)}

		dispo = "pending"
		dispo = "complete" if agent

		# If we have exceded our retry count then set the callee to failed
	    max_attempts = cdr.campaign.settings.to_hash[:max_attempts]
	    dispo = "failed" if  cdr.callee.dial_attempts >= max_attempts && !agent

		# If this call was hungup by an agent, then don't change the status
	    callee_data[:status] = dispo unless cdr.dispositioned_by_agent

	    # Update the callee
	    cdr.callee.update( callee_data )

	    # Don't perform agent status updtaes until the agent actually hangsup
	    # Update agent without callbacks
    	agent.this.update({last_call_at: notif[:agent_answered_at]}) if agent

	    # puts "EA: #{notif[:ended_at].class} === #{notif[:ended_at].to_i}"
	    # puts "CA: #{notif[:callee_answered_at].class} === #{notif[:callee_answered_at].to_i}"
	    # puts "DA: #{notif[:dialed_at].class} === #{notif[:dialed_at].to_i}"
	    # puts "AA: #{notif[:agent_answered_at].class} === #{notif[:agent_answered_at].to_i}"

	    time_elapsed = notif[:ended_at].to_i - notif[:callee_answered_at].to_i
	    hold_time = notif[:agent_answered_at].to_i - notif[:callee_answered_at].to_i
	    ring_time = notif[:callee_answered_at].to_i - notif[:dialed_at].to_i

	    if (notif[:callee_answered_at].to_i == 0) 
	    	time_elapsed = 0
	    	ring_time = notif[:ended_at].to_i - notif[:dialed_at].to_i
	    end

	    hold_time = 0 if (hold_time < 0)
        ring_time = 0 if (ring_time < 0) 

	    update_data = {disposition: notif[:end_reason], dialed_at: notif[:dialed_at], 
						call_time: time_elapsed, hold_time: hold_time, ring_time: ring_time, 
						agent: agent, uuid: notif[:uuid], recording_url: notif[:recording_location],
						route: notif[:call_dir], end_code: notif[:end_code]}

		update_data.delete(:disposition) if cdr.dispositioned_by_agent

	    cdr.update(update_data)
	end

	def logger
		SuckerPunch.logger
	end
end