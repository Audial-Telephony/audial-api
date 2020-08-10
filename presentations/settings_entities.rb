require_relative 'settings_entities'

module API
  module Entities
    class Settings < Grape::Entity
      root 'settings'

      expose :outbound_call_id
      expose :dial_aggression
      expose :wrapup_time
      expose :call_timeout
      expose :hold_timeout
      expose :max_attempts
      expose :dial_from_self
    
    end
  end
end