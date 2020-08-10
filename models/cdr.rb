class CDR < Sequel::Model(:cdr)
	plugin :schema

	many_to_one :campaign
	many_to_one :agent
	many_to_one :callee

	# Use for more complex operations
	# dataset_module do
	# 	def answered
	# 		where {disposition: "answered"}
	# 	end
	# end

	subset(:answered){ disposition == "answered"}
	subset(:busy){ disposition == "busy"}

	def to_report
		report = {}
		report[:id] = self.id
		report[:campaign_ref] = self.campaign_ref
		report[:agent] = self.agent_extension
		report[:contact_ref] = self.contact_ref
		report[:number_dialed] = self.number_dialed
		report[:recording_url] = self.recording_url
		report[:disposition] = self.disposition
		report[:dialed_at] = self.dialed_at
		report[:ring_time] = self.ring_time
		report[:hold_time] = self.hold_time
		report[:call_time] = self.call_time

		report
	end
	
	def agent_extension
		self.agent.extension if self.agent
	end

	def campaign_ref
		self.campaign.ref if self.campaign
	end

	def campaign_outbound_number
		self.campaign.settings.outbound_call_id if self.campaign
	end

	def contact_ref
		self.callee.ref if self.callee
	end

	def hangup_call
		disposition_call(:agent_hungup, false)
	end

	def retry_number
		self.callee.update({status: "pending"})
		disposition_call(:retry, true)
	end

	def close_matter
		self.callee.update({status: "complete"})
		disposition_call(:closed, true)
	end

	def hangup_and_remove_number
		# Update the time here to prevent immediate call back
		self.callee.update({status: "pending", numbers:[{n: self.number_dialed, p:"-1"}], last_dialed_at: Time.now.to_i})
		
		disposition_call(:remove_number, true)
	end

	def disposition_call(reason, by_agent = false)
		self.update({disposition: reason.to_s, dispositioned_by_agent: by_agent})
		REDIS_NOTIF.publish("call:management", {type: "disposition", call_ref: self.id, uuid: self.uuid, disposition: reason.to_s}.to_json)
	end

end