require 'spec_helper'
require_relative File.dirname(__FILE__) + '/../../../models/agent'
require_relative File.dirname(__FILE__) + '/../../../spec/factories/campains_factory'
require_relative File.dirname(__FILE__) + '/../../../spec/factories/agents_factory'
require_relative File.dirname(__FILE__) + '/../../../lib/static_variables'
include CampainsFactory
include AgentsFactory
include StaticVariables

describe Dialer::App do
  include Rack::Test::Methods

  def app
    Dialer::App.new
  end

  ################### specs #################

  describe "Successfull Agent creation" do

    context "when agent extension does not exist" do
      it 'returns 201 and agent is created successfully' do
        extension = "#{Time.now.nsec.to_i}"
        lambda do
          response = JSON.parse(create_campaign("#{Time.now.nsec.to_i}").body)
          json_new_agent = {
              agent: {
                        campaign_ref: response["campaign"]["campaign_ref"], "extension": extension, status:"available"
                      }
          }
          post "/agents" , json_new_agent
        end.should change(Agent, :count).by(1)
        last_response.status.should == 201
        JSON.parse(last_response.body)["agent"].should include("extension"=>extension)
      end
    end

    context "when agent extension  exist" do
      let!(:agent_creation_response) { JSON.parse(create_agent("#{Time.now.nsec.to_i}").body) }

      it 'returns 201 and existing agent is successfullu updated' do
        lambda do
          response = JSON.parse(create_campaign("#{Time.now.nsec.to_i}").body)
          json_new_agent = {
              agent: {
                        campaign_ref: response["campaign"]["campaign_ref"],
                        extension: agent_creation_response["agent"]["extension"],
                        status: "available"
                      }
          }
          post "/agents", json_new_agent
        end.should_not change(Agent, :count)
          last_response.status.should == 201
          JSON.parse(last_response.body)["agent"].should include("extension"=>agent_creation_response["agent"]["extension"])
      end
    end

  end

  describe "Error in Agent creation" do

    let (:extension) {Time.now.nsec.to_i}
    let (:campaign_1 ) { JSON.parse(create_campaign("#{Time.now.nsec.to_i}", {status: "started"}).body)}
    let (:campaign_2 ) { JSON.parse(create_campaign("#{Time.now.nsec.to_i}").body)}
    let(:inexisting_campaign_ref) {Time.now.nsec.to_i}

    it "returns 400 when the status is invalid" do
      status ="xyz"
      json_new_agent = {
          agent: {
                    campaign_ref: campaign_1["campaign"]["campaign_ref"],
                    extension: extension,
                    status: status
                  }
      }

      post "/agents" , json_new_agent
      last_response.status.should == 400
      JSON.parse(last_response.body).should == {"errors"=>["Agent Error: Requested invalid status[#{status}] for Agent[#{extension}]"]}
    end

    it "returns 404 when campaign_ref does not exist" do
      json_new_agent = {
          agent: {
                    campaign_ref: inexisting_campaign_ref,
                    extension: extension,
                    status: "available"
                  }
      }

      post "/agents", json_new_agent
      last_response.status.should == 404
      JSON.parse(last_response.body).should == {"errors" => ["Campaign Error: Campaign[#{inexisting_campaign_ref}] does not exist"]}
    end

    it "returns 409 when agent is already in a started campaign" do
      pending "Waiting for DIAL-318 to be resolved"
      adding_agent_in_started_campaign = {
          agent: {
                    campaign_ref: campaign_1["campaign"]["campaign_ref"],
                    extension: extension,
                    status: "available"
                }
      }

      try_adding_agent_in_another_campaign = {
          agent: {
                    campaign_ref: campaign_2["campaign"]["campaign_ref"],
                    extension: extension,
                    status: "available"
                  }
      }

      post "/agents" , adding_agent_in_started_campaign
      post "/agents" , try_adding_agent_in_another_campaign
      last_response.status.should == 409
      JSON.parse(last_response.body).should == {"errors"=>["Agent Error: Agent[#{extension}] already in Campaign[#{campaign_1['campaign']['campaign_ref']}]"]}
    end

  end


  describe "Agent status update" do
    context "when the status is valid" do
      let!(:agent_creation_response) {JSON.parse(create_agent("#{Time.now.nsec.to_i}").body) }
      it "updates successfully the agent status" do

          response = JSON.parse(create_campaign("#{Time.now.nsec.to_i}").body)
          json_update_agent = {agent: {"extension": agent_creation_response["agent"]["extension"], status:"offline"} }
          put "/agents/#{agent_creation_response["agent"]["extension"]}" , json_update_agent

        last_response.status.should == 200
        JSON.parse(last_response.body).should eq( {
            "agent"=>{"extension"=>"#{agent_creation_response['agent']['extension']}", "status"=>"offline",
            "last_call_at"=>"#{agent_creation_response['agent']['last_call_at']}"}
        }
      )
      end
    end

    context "when the status is invalide" do
      let!(:agent_creation_response) {JSON.parse(create_agent("#{Time.now.nsec.to_i}").body) }
      let(:invalid_status) {"xyz"}
      it "returns an error" do

        response = JSON.parse(create_campaign("#{Time.now.nsec.to_i}").body)
        json_update_agent = {agent: {"extension": agent_creation_response["agent"]["extension"], status: invalid_status} }
        put "/agents/#{agent_creation_response["agent"]["extension"]}" , json_update_agent

        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors"=>["Agent Error: Requested invalid status[#{invalid_status}] for Agent[#{agent_creation_response["agent"]["extension"]}]"]}

      end
    end

  end



  describe "Modifiying an agent attributes" do

    let(:ref) {"#{Time.now.nsec.to_i}"}
    let(:ref2) {"#{Time.now.nsec.to_i}"}
    let(:agent_creation_response) {JSON.parse(create_agent(ref).body) }
    let!(:campaign_creation_response) {JSON.parse(create_campaign(ref2).body) }
    let(:invalid_status) {"xyz"}

    context "when providing body  with all valid parameters" do

       it "updates successfully the agent details" do
          json_update_agent = {agent: {extension: agent_creation_response["agent"]["extension"], status: "offline" }}
          put "/agents/#{agent_creation_response["agent"]["extension"]}" , json_update_agent

          last_response.status.should == 200
          JSON.parse(last_response.body)["agent"].should include("status"=>"offline")
       end
    end

    context "when providing body with invalid agents paramters" do

      it "returns 400 status with error message" do
        json_update_agent = {agent: {"extension": agent_creation_response["agent"]["extension"], status: invalid_status }}
        put "/agents/#{agent_creation_response["agent"]["extension"]}" , json_update_agent
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors"=>["Agent Error: Requested invalid status[#{invalid_status}] for Agent[#{agent_creation_response["agent"]["extension"]}]"]}
      end
    end

    context "agent does not exist" do

      it "returns 404 with error message" do
        json_update_agent = {agent: {extension: 1111, status: "offline" }}
        put "/agents/1111" , json_update_agent

        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"errors"=>["Agent Error: Agent[1111] does not exist"]}
      end

    end

    context "campaign does not exist" do

      it "returns 404 with error message" do

        json_update_agent = {agent: {extension: agent_creation_response["agent"]["extension"], status: "offline", campaign_ref: "ref-123" }}
        put "/agents/#{agent_creation_response["agent"]["extension"]}" , json_update_agent

        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"errors"=>["Campaign Error: Campaign[#{json_update_agent[:agent][:campaign_ref]}] does not exist"]}
      end

    end

  end


  describe "Delete an agent" do
    let!(:ref) {"#{Time.now.nsec.to_i}"}
    let(:ref2) {"#{Time.now.nsec.to_i}"}
    let!(:agent_creation_response) {JSON.parse(create_agent(ref).body) }
    let!(:campaign_creation_response) {JSON.parse(create_campaign(ref2).body) }

    context "when Success" do

      it "returns 200" do
        delete "/agents/#{agent_creation_response["agent"]["extension"]}/#{ref}"
        last_response.status.should == 200
        JSON.parse(last_response.body)["agent"].should include({"extension"=>ref})
      end

    end

    context "Failure during delete" do

      it "returns 404 and a failure error when extension not found" do
        delete "/agents/1234567/#{ref}"
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"errors"=>["Agent Error: Agent[1234567] does not exist"]}
      end

      it "returns 404 and a failure error when campaign not found" do
        delete "/agents/#{agent_creation_response["agent"]["extension"]}/1234567"
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"errors"=>["Campaign Error: Campaign[1234567] does not exist"]}
      end

      it "returns 404 and a failure error when extension not in campaign" do
        delete "/agents/#{agent_creation_response["agent"]["extension"]}/#{ref2}"
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {
            "errors"=>["Agent Error: Agent[#{agent_creation_response["agent"]["extension"]}] is not in Campaign[#{ref2}]"]
        }
      end
    end

  end

  describe "Retrieve a single agent" do
    let!(:ref) {"#{Time.now.nsec.to_i}"}
    let(:ref2) {"#{Time.now.nsec.to_i}"}
    let!(:agent_creation_response) {JSON.parse(create_agent(ref).body) }
    let!(:campaign_creation_response) {JSON.parse(create_campaign(ref2).body) }

    context "When success" do

      it "returns 200 with the agent information" do
        get "/agents/#{agent_creation_response["agent"]["extension"]}/#{ref}"
        last_response.status.should == 200
        agent = JSON.parse(last_response.body)["agent"]
        agent.should include(
                         "extension" => ref,
                         "status" => "available"
                     )
        agent.should  == agent_creation_response["agent"].merge("calls"=>[])
      end
    end

    context "When failure" do

      it "returns 404 and a failure error when extension not found" do
        get "/agents/1234567/#{ref}"
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"errors"=>["Agent Error: Agent[1234567] does not exist"]}
      end

      it "returns 404 and a failure error when campaign not found" do
        get "/agents/#{agent_creation_response["agent"]["extension"]}/1234567"
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"errors"=>["Campaign Error: Campaign[1234567] does not exist"]}
      end

      it "returns 404 and a failure error when extension not in campaign" do
        get "/agents/#{agent_creation_response["agent"]["extension"]}/#{ref2}"
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {
            "errors"=>["Agent Error: Agent[#{agent_creation_response["agent"]["extension"]}] is not in Campaign[#{ref2}]"]
        }
      end

    end
  end

  ############################################
end
