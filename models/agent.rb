class Agent < Sequel::Model(:agents)
	plugin :instance_hooks
	plugin :validation_helpers
	require_relative '../lib/campaign_error'
	many_to_many :campaigns#this throws an error I prefer quiet failure, :before_add => proc{|ag, cm| false if (ag.campaigns_dataset.where(id: cm.id).count > 0)}
	one_to_many :cdr, class: :CDR

	def validate
		super
		validates_presence :extension
		validates_unique :extension
		# validates_includes ["away","busy","available","offline"], :status
		#validates_unique :name
		#validates_format /\Ahttps?:\/\//, :website, :message=>'is not a valid URL'
	end

	# Add the new agent to the specific campaign
	def campaign_ref=(c_ref)
		parent = Campaign[ref: c_ref]
		raise CampaignError.new, "Campaign Error: Campaign[#{c_ref}] does not exist" unless parent
		isnew_assoc = new? || (self.campaigns_dataset.where(id: parent.id).count == 0)
		self.modified! if isnew_assoc
		after_save_hook{ 
			if isnew_assoc 
				self.add_campaign(parent)
			end 
		}
	end

	def campaign_ref
		Campaign[self.campaign_id].ref
	end

	def cdr_for_campaign(campaign_ref)
		campaign = Campaign[ref: campaign_ref]
		raise CampaignError.new, "Campaign Error: Campaign[#{campaign_ref}] does not exist" unless campaign
		self.cdr.keep_if{|call| call.campaign_id == campaign.id}
	end

	# Update an existing object or create a new one
	# Also return whether the object was created or already existing
	def self.update_or_create(attrs, set_attrs=nil, campaign_id=nil)
		# This ensures we don't accidently edit state for a campaign that is running already
		# while uploading new data
		@current_campaign = Campaign[campaign_id].ref if campaign_id

		#logger.info "Update or Create agent: #{attrs} - #{set_attrs} - #{@current_campaign}"

		obj = Agent[attrs] || Agent.new(attrs)
		isnew = obj.new?
		obj.save if isnew

		if (isnew && set_attrs[:status].nil?)
			set_attrs[:status] = "offline"
		end

		# # Don't fire callbacks here, they will be fired by the Campaign side
		obj.this.update(set_attrs)

		# Check if the agent is new in this specific campaign
		if (campaign_id)
			cnt = obj.campaigns_dataset.where(id: campaign_id).count
			isnew = (cnt > 0) ? false : true
			
			if (isnew)
				campaign = Campaign[id: campaign_id]
				obj.add_campaign(campaign)
			end
		end

		return obj, isnew
	end

	def status=(param)
		# @old_status = self.status
		@status_modified = true
		self.modified!(:status)

		super(param)
	end

	def requeue_agent(campaign_ref)
		_add_agent_to_dialer(campaign_ref)
	end

	def log_agent_out(campaign_ref)
		@current_campaign = campaign_ref
		self.update({status: :offline})
	end

	def after_save
		super

		_add_agent_to_dialer(@current_campaign)
	end

	def before_destroy
		_remove_agent_from_dialer

		self.remove_all_cdr
		self.remove_all_campaigns

		super
	end

	# add agent to dialer when:
	# 	- agent does not exist on dialer & their status is available & campaign exists on dialer
	# 	- when a campaign changes to started mode and the agent is not already on the dialer
	def get_active_campaign_ref(c_ref = nil)
		c_ref = self.campaigns_dataset.where(status: ["started", "stopping"]).last.try(:ref) if c_ref.nil?
		c_ref
	end

	def _add_agent_to_dialer(campaign_ref = nil)
		#logger.info "Sending #{self.extension} - #{@current_campaign} - #{campaign_ref}"
		campaign_ref = get_active_campaign_ref(campaign_ref)

		#logger.info "#{self.extension}    cref #{campaign_ref} "

		unless campaign_ref.nil?
				data = {
					extension: self.extension,
					status: self.status,
					campaign_ref: campaign_ref,
				}
				
				#logger.info "Sending the agent data to the dialer - #{data}"
				_send_dialler_request(:agent, data)
				# REDIS.publish "agents", data.to_json #if @status_modified
		end		
	end

	# Inverse of add_agent_to_dialer
	# Used when shutting down a campaign
	def _remove_agent_from_dialer(campaign_ref = nil)
		campaign_ref = get_active_campaign_ref(campaign_ref)

		unless campaign_ref.nil?
			data = {}
			data[:extension] = self.extension
			data[:status] = self.status,
			data[:campaign_ref] = campaign_ref

			# REDIS.publish "agents", data.to_json
			_send_dialler_request(:agent, data)
		end	
	end

	def _send_dialler_request(type, data)
		notif = {type: type, payload: data}
		REDIS_NOTIF.rpush 'enigma:api', notif.to_json
	end

end
