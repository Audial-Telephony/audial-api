module API
  module Entities
    class Campaigns < Grape::Entity
      root 'campaigns', 'campaign'

      expose :name
      expose :ref, as: :campaign_ref
      expose :status

      expose :settings, using: 'API::Entities::Settings', as: :settings, if: {type: :full_campaign}
      expose :settings, using: 'API::Entities::Settings', as: :settings, if: {type: :with_settings}
      expose :callees, using: 'API::Entities::Callees', as: :callees, if: {type: :full_campaign}
      expose :agents, using: 'API::Entities::Agents', as: :agents, if: {type: :full_campaign}
   
    end
  end
end