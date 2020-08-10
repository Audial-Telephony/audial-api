Sequel.migration do
	up do
		create_table(:campaigns) do 
			primary_key :id
		    String :ref, 				unique: true
		    String :name
		    String :status, 			default: "stopped"
		end

		create_table(:agents) do 
			primary_key :id
		    String :extension, 			unique: true
		    String :status,				default: "offline"
		    Time :last_call_at,			default: Time.utc(2014,01,01)
		end

		create_table(:agents_campaigns) do 
		    foreign_key :agent_id, :agents
			foreign_key :campaign_id, :campaigns    
		end

		create_table(:callees) do 
			primary_key :id
		    String :ref, 				unique: true
		    String :status,				default: "pending"
		    Time :last_dialed_at,		default: Time.utc(2014,01,01)
		    foreign_key :campaign_id
		    # All the numbers are stored in Redis
		end

		create_table(:settings) do
			primary_key :id
			String :outbound_call_id, 	default: "0123456789"
		    Integer :dial_aggression, 	default: 3
		    Integer :wrapup_time, 		default: 0
		    Integer :call_timeout,		default: 0
		    Integer :hold_timeout,		default: 0
		    Integer :max_attempts,		default: 30
		    Integer :retry_timeout, 	default: 1800 #Half an hour between calls
		    TrueClass :dial_from_self,	default: false
		    String :notif_type,			default: "sip"
		    String :campaign_type,		default: "progressive"
		    String :moh,				default: 'moh'
			foreign_key :campaign_id
		end

		create_table(:cdr) do 
		    primary_key :id
		    String :uuid, 	unique: true
		    foreign_key :campaign_id, :campaigns
		    foreign_key :agent_id, :agents
		    foreign_key :callee_id, :callees
		    String :number_dialed
		    String :recording_url
		    String :disposition
		    Time :dialed_at
		    Integer :ring_time 
		    Integer :hold_time 
		    Integer :call_time
		    String :route
		    TrueClass :dispositioned_by_agent, default: false
		end
	end

	down do
		drop_table(:agents_campaigns)
		drop_table(:cdr)
		drop_table(:settings)
		drop_table(:campaigns)
		drop_table(:callees)
		drop_table(:agents)
	end
end