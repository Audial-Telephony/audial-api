module Dialer
  class V2 < Grape::API
    format :json
    version 'v2', using: :header, vendor: 'teleforge', format: :json, cascade: true
    rescue_from Grape::Exceptions::ValidationErrors do |e|
      error!({ errors: e.full_messages }, 400)
    end

    rescue_from Sequel::Rollback do |e|
      error!({ errors: e.full_messages }, 404)

    end

    desc "Returns the current API version, v2."
    get do
      { version: 'v2' }
    end
  end
end
