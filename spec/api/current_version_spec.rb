require 'spec_helper'

describe Dialer::App do
  include Rack::Test::Methods

  def app
    Dialer::App.new
  end

  context "current" do
    it "root returns v1" do
      get "/"
      last_response.status.should == 200
      last_response.body.should == { version: "v1" }.to_json
    end
    it "ping falls back to v1" do
      get "/ping"
      last_response.status.should == 200
      last_response.body.should == { ping: "pong" }.to_json
    end
  end

end

