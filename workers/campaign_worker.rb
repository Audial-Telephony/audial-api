class CampaignWorker
	include SuckerPunch::Job

	def perform(campaign_ref, queue_rate = 30)
		# Lock the mutex and queue calls if we got a lock otherwise just return
		lock("mutex:#{campaign_ref}", 10) {
			queue_some_calls(campaign_ref, queue_rate)
		}
	end

	def redis
		begin
				@redis ||= Redis.new(:url => ENV['NOTIF_REDIS_URL'])
		    @redis.ping
		rescue Redis::BaseConnectionError => error
			logger.warn "Campaign Worker: #{error}, retrying in 1s"
			sleep(1)
			retry
		end
		@redis
	end

	def queue_some_calls(campaign_ref, queue_rate)
		@campaign_ref = campaign_ref
		@campaign = Campaign[ref: @campaign_ref]

		logger.info "Campaign Worker Fired Up For: #{@campaign_ref} -- #{@campaign}"

		if @campaign.nil?
			return
		end

		retry_timeout = @campaign.settings.to_hash[:retry_timeout]
	    
	    unless retry_timeout
	      retry_timeout = 1800
	      logger.warn "Retry timeout is unspecified; defaulting to #{retry_timeout}s"
	    end

		callees = grab_callees_to_dial(queue_rate, retry_timeout)

		logger.info "[grab_callees_to_dial/#{campaign_ref}]: count - #{queue_rate}, timeout - #{retry_timeout}, callees - #{callees.count}"

		dial_preview_list = []

		# Some condition for setting the campaign to completed
		unless callees.empty?

			redis.multi do
				callees.each do |callee|
					number = callee.next_number

					if number.nil? || number.empty?
						if callee.numbers_count == 0
							callee.update({status: "failed"})
						end
					else
						logger.info "DIALING #{number}"
						callee.update({ last_dialed_at: Time.now, status: "dialing" })

						call = CDR.create({campaign_id: @campaign.id, callee_id: callee.id, number_dialed: number})
						data = {number: number, contact_ref: callee.contact_ref, call_ref: call.id}

						redis.rpush "campaign:#{@campaign_ref}:calls:todial", data.to_json

						dial_preview_list << { number: number, contact_ref: callee.contact_ref }
					end
				end
			end
		end

		send_update(dial_preview_list)
	end

	# This sends updated information to the dialler about how many matters still need to be dialled. It is executed everytime new matters
	# are asked for.
	def send_update( dial_preview_list )
		data = {}
		data[:campaign_ref] = @campaign_ref
		data[:pending_callees] = pending_callees.count
		data[:currently_dialing] = currently_dialing_callees.count
		data[:completed_callees] = completed_callees.count
		data[:failed_callees] = failed_callees.count
		data[:dial_preview_list] = dial_preview_list

		notif = { type: :queue_update, payload: data }

		redis.rpush "enigma:api", notif.to_json
	end

	# Get the callees for a campaign that haven't yet been successfuly dialed,
	# and have been idle long enough to try again
	def grab_callees_to_dial(limit, timeout)
		Callee.where(campaign_id: @campaign.id, status: "pending").filter('last_dialed_at < ?', Time.now - timeout).order(:last_dialed_at,:id).limit(limit)
	end

	def pending_callees
		Callee.where(campaign_id: @campaign.id, status: "pending")
	end

	def currently_dialing_callees
		Callee.where(campaign_id: @campaign.id, status: "dialing")
	end

	def completed_callees
		Callee.where(campaign_id: @campaign.id, status: "complete")
	end

	def failed_callees
		Callee.where(campaign_id: @campaign.id, status: "failed")
	end

	# Simple REDIS based mutex to ensure each campaign only has 1 worker trying to add calls to the queue
	# otherwise the behaviour is undefined. Additional workers are just closed as they will call again if more 
	# calls are really needed
	# The 30 second expire ensures that the mutex doesn't accidently stay locked if the worker crashes
	def lock(key, timeout = 3600)
	  if (_lock_mutex(key, timeout))
	    begin
	      yield
	    ensure
	      redis.del key
	    end
	  end
	end

	def _lock_mutex(key, timeout)
		success = redis.setnx key, 1
		redis.expire(key, timeout) if success
		return success
	end

	def logger
		SuckerPunch.logger
	end

end

# Start the worker
# The worker is started in the API app.rb file. It only needs to be started once when the API is loaded

# To load sidekiq run
# b sidekiq -r ./config/application.rb
