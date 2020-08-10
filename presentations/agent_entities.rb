module API
  module Entities
    class Agents < Grape::Entity
      root 'agents', 'agent'

      expose :extension
      expose :status
      expose :last_call_at

      expose :campaigns, using: 'API::Entities::Campaigns', as: :campaigns, if: {type: :with_camps}
    
      expose :cdr, using: 'API::Entities::CDR', as: :calls, if: {type: :full_agent} do |instance, options|
    		if options[:campaign]
    		    instance.cdr_for_campaign(options[:campaign])
    		else
    		    instance.cdr
    		end
	    end

    end
  end
end