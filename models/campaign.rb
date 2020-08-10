class Campaign < Sequel::Model(:campaigns)
	plugin :instance_hooks
	plugin :nested_attributes
	plugin :validation_helpers
    
	one_to_many :callees #,key: :campaign_ref
	many_to_many :agents #,left_key: :campaign_ref, right_key: :agent_extension, join_table: :agents_campaigns
	one_to_many :cdr, class: :CDR
	one_to_one :settings

	def validate
	    super
	    validates_presence [:ref, :status]
	    validates_max_length 50, :name, :message =>"Maximum length is 50"  if !name.blank?
	    errors.add(:ref, 'cannot be empty') if !ref || ref.empty?
	    validates_includes ["started","stopped","completed","stopping"], :status , :message=>" #{status} is invalid!"
	end

	def _get_settings_for_dialer
		settings_tmp = Settings[campaign_id: self.id]
		settings_tmp.to_hash.reject!{|k,v| [:id,:campaign_id,:max_attempts,:retry_timeout].include?(k)}
		settings_tmp.to_hash
	end

	def _add_campaign_to_dialer
		# We cannot update settings for stopped and completed campaigns as there is no info
		# on the dialler for them
		if @agent_action || ( @settings_modified && ( self.status == 'started'  || self.status == 'stopping' ) )
			data = {}
			data[:campaign_ref] = self.ref

			case status.to_sym
			when :started
				d_status = :start
			when :stopped
				d_status = :stop
			when :completed
				d_status = :stop
			end

			data[:status] = d_status if @agent_action
			data[:settings] = _get_settings_for_dialer
		
			#logger.info "Adding campaign to dialer - #{data}"

			_send_dialler_request( :campaign, data )
		end

		case @agent_action
		when :login_agents
			requeue_all_agents
		when :logout_agents
			set_all_agents_offline
		end
	end

	def _remove_campaign_from_dialer
		data = {
			campaign_ref: self.ref,
			status: 'stop',
			settings: _get_settings_for_dialer,
		}
		
		_send_dialler_request( :campaign, data )
		# REDIS.publish "campaigns", data.to_json
	end

	def _send_dialler_request(type, data)
		notif = {type: type, payload: data}
		REDIS_NOTIF.rpush 'enigma:api', notif.to_json
	end

	# Our API uses unique_ref instead of just ref, this fixes the issue
	def campaign_ref=(unique_ref)
		self.ref = unique_ref
	end

	def campaign_ref
		self.ref
	end

	def settings=(settings_attr)
		settings = self.settings || Settings.new
		isnew = settings.new?
		settings.set(settings_attr)

		if settings.modified? 
			self.modified!(:ref)
			@settings_modified = true
		end

		after_save_hook{ settings.set({campaign_id: self.id}).save }
	end

	# So we can pass in the hash we receive and automatically create the callees
	def callees=(callees)

		callees.each do |callee_params|
			callee_params.symbolize_keys!

      # Validate that a call_ref is present. Do this here instead of a validation
      # on the model because inbound calls won't have a call_ref
      raise "call_ref is a required parameter" unless callee_params[:contact_ref].present?

			# Hack to ensure the callback is fired but not set all values to modified
			# As we later check if the status was actually modified
			# Safe to do as ref can never be updated
			self.modified!(:ref)

			callee, isnew = Callee.update_or_create({ref: callee_params[:contact_ref]}, callee_params)
			after_save_hook{ callee.update({campaign_id: self.id}) }
		end
	end

	def agents=(agents)
		# DB.transaction do
		agents.each do |agent_params|
			agent_params.symbolize_keys!

			# Hack to ensure the callback is fired but not set all values to modified
			# As we later check if the status was actually modified
			# Safe to do as ref can never be updated
			self.modified!(:ref)

			# New in this context also means new to this campaign, and not just a new entity
			after_save_hook{
				Agent.update_or_create({extension: agent_params[:extension]}, agent_params, self.id)
			}
		end
		# end
	end

	def set_all_agents_offline
		#logger.info "LOGOUT all agents "
		# self.agents.map{ |a| a.log_agent_out(self.ref) }
	end

	def requeue_all_agents
		# Just give it a second to reflect that the campaign is started
		sleep 1

		#logger.info "Requeue all agents "
		self.agents.map{ |a| a.requeue_agent(self.ref) }
	end

	def status=(param)
		unless param.to_s == self.status
			@modified_status = true;
      case param.try(:to_sym)
			when :started
				@agent_action = :login_agents
			when :stopped
				@agent_action = :logout_agents unless self.status.nil?
			when :completed
				@agent_action = :logout_agents unless self.status.nil?
			end
		end

		super(param)
	end

	def after_save
		super 
		_add_campaign_to_dialer
	end

	def before_destroy
		_remove_campaign_from_dialer

		# There is an issue here in that the agents aren't deleted 
		# Clean up all associated records
		tmp_cdr = self.cdr_dataset
		# tmp_agents = self.agents_dataset
		tmp_callees = self.callees_dataset
		
		self.remove_all_cdr
		self.remove_all_agents
		self.remove_all_callees
		# self.callees_dataset.destroy
		self.settings_dataset.destroy

		tmp_cdr.destroy
		# tmp_agents.destroy
		tmp_callees.destroy
					
		super
	end

end
