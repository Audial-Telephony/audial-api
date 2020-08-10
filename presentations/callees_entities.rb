module API
  module Entities
    class Callees < Grape::Entity
		root 'callees', 'callee'

		expose :ref, as: :contact_ref
		expose :campaign_ref, unless: {type: :full_campaign}
		expose :primary_number, unless: {type: :full_callee}
		expose :last_dialed_at
		expose :status
		expose :dial_attempts
    	
    	expose :numbers, if: {type: :full_callee}
    	expose :cdr, using: 'API::Entities::CDR', as: :calls, if: {type: :full_callee}
    end
  end
end