module API
  module Entities
    class CDR < Grape::Entity
		root 'calls', 'call'

		expose :id, as: :call_id
		# expose :uuid
		expose :number_dialed
		expose :recording_url, as: :recording_location
		expose :disposition, as: :disposition
		expose :dialed_at
		expose :hold_time
		expose :call_time
		expose :agent_extension, as: :agent, if: {type: :full_callee}
		expose :contact_ref, as: :contact_ref, if: {type: :full_agent}
		expose :campaign_ref, as: :campaign_ref, if: {type: :full_agent}

    end
  end
end