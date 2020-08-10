require_relative 'base/campaigns'
require_relative 'base/callees'
require_relative 'base/agents'
require_relative 'base/calls'
require_relative '../lib/campaign_error'


module Dialer
  class V1 < Grape::API
    # version [ 'v2', 'v1' ], using: :header, vendor: 'acme', format: :json, cascade: true
    version 'v1', using: :header, vendor: 'teleforge', format: :json, cascade: true
    format :json

    rescue_from CampaignError do |e|
      error!({ errors: [e.message] }, 404)

    end

    rescue_from CalleeError do |e|
      error!({ errors: [e.message] }, 409)

    end

    rescue_from Grape::Exceptions::ValidationErrors do |e|
      error!({ errors: e.full_messages }, 400)
    end



    # error_format :json

    rescue_from Sequel::Error do |e|
      Rack::Response.new({error: "failed", message: e.message }, 404, { 'Content-type' => 'application/json' }).finish
      V1.logger.error "#{e.message}"
    end


    rescue_from :all do |e|
      # Log it
      # Rails.logger.error "#{e.message}\n\n#{e.backtrace.join("\n")}"

      # Notify external service of the error
      # Airbrake.notify(e)

      # Send error and backtrace down to the client in the response body (only for internal/testing purposes of course)
      V1.logger.error "#{e.message}\n\n#{e.backtrace.join("\n")}"
      # Rack::Response.new({ message: e.message, backtrace: e.backtrace }, 500, { 'Content-type' => 'application/json' }).finish
      Rack::Response.new({ message: e.message }, 500, { 'Content-type' => 'application/json' }).finish
    end

    desc "Returns the current API version, v1."
    get do
      { version: 'v1' }
    end

    desc "Returns pong."
    get "ping" do
      { ping: "pong" }
    end

    desc "TeleforgeRocksYourSocks"
    get "tf" do
      { truth: "TeleforgeRocksYourSocks" }
    end

    mount Dialer::Campaigns
    mount Dialer::Callees
    mount Dialer::Agents
    mount Dialer::Calls
    mount Dialer::Management

  end
end
