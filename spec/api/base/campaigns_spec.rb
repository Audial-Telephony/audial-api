require 'spec_helper'
require_relative File.dirname(__FILE__) + '/../../../models/campaign'
require_relative File.dirname(__FILE__) + '/../../../spec/factories/campains_factory'

describe Dialer::App do
  include Rack::Test::Methods
  include CampainsFactory

  def app
    Dialer::App.new
  end

  ################### specs #################

  describe "Campaign creation" do

    context "Success case" do
      let (:ref) { "#{Time.now.to_i}" }
      it 'creates a campaign, should add 1 compaign to the DB' do
        lambda do
          create_campaign(ref)
        end.should change(Campaign, :count).by(1)
        last_response.status.should == 201
      end

    end

    context "Failure cases" do
      let(:invalid_status) { {status: "xyz"} }
      let(:invalid_moh) { {settings: {moh: "xyz"}} }
      let(:invalid_agent_moh) { {settings: {agent_moh: "xyz"}} }
      let(:invalid_campaign_type) { {settings: {campaign_type: "xyz"}} }

      before(:each) do
        @ref = "#{Time.now.nsec.to_i}"
      end
      it "returns 400 status with error message when campaign status is invalid" do
        lambda do
          create_campaign(@ref, invalid_status)
        end.should_not change(Campaign, :count)
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors" => ["Campaign Error: Incorrect value[xyz] for field[status]"]}
      end

      it "returns 400 status with error message when campaign campaign_type is invalid" do
        lambda do
          create_campaign(@ref, invalid_campaign_type)
        end.should_not change(Campaign, :count)
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors" => ["Campaign Error: Incorrect value[xyz] for field[campaign_type]"]}

      end

      it "returns 400 status with error message when campaign moh is invalid" do
        pending "Waiting for DIAL-470 to be resolved"
        lambda do
          create_campaign(@ref, invalid_moh)
        end.should_not change(Campaign, :count)
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors" => ["Campaign Error: Incorrect value[xyz] for field[moh]"]}
      end

      it "returns 400 status with error message when campaign agent_moh is invalid" do
        pending "Waiting for DIAL-470 to be resolved"
        lambda do
          create_campaign(@ref, invalid_agent_moh)
        end.should_not change(Campaign, :count)
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors" => ["Campaign Error: Incorrect value[xyz] for field[agent_moh]"]}
      end

      it "returns 400 status when mandatory filed is missing " do
        #TODO there is no mandatory field to validate for this case
      end
    end
  end

  describe "Campaign modification" do

    context "Success case" do
      let! (:ref) { "#{Time.now.nsec.to_i}" }
      let(:new_name) { new_name = "New Name #{ref}" }
      let(:options) { {name: new_name} }

      it "update the given attributes if the campaign exists" do
        create_campaign(ref)
        new_name = "New Name #{ref}"
        json_updated_campaign = instantiate_campaign(ref, options)

        put "/campaigns/#{ref}", json_updated_campaign
        last_response.status.should == 200
        last_response.body.include?(new_name).should be_true
      end

      it "creates the campaign when it does not exist" do
        lambda do
          ref_1 = "#{Time.now.nsec.to_i}"
          json_updated_campaign = instantiate_campaign(ref)
          put "/campaigns/#{ref_1}", json_updated_campaign
        end.should change(Campaign, :count).by(1)
        last_response.status.should == 200
      end
    end

    context "Failure cases" do
      let(:invalid_status) { {status: "DDD"} }
      let(:invalid_moh) { {settings: {moh: "xyz"}} }
      let(:invalid_agent_moh) { {settings: {agent_moh: "xyz"}} }
      let(:invalid_campaign_type) { {settings: {campaign_type: "xyz"}} }
      let(:ref) { "#{Time.now.nsec.to_i}" }
      let!(:campaign) { create_campaign(ref) }

      it "returns 400 status with error message when campaign status is invalid" do
        json_updated_campaign = instantiate_campaign(ref, invalid_status)
        put "/campaigns/#{ref}", json_updated_campaign
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors" => ["Campaign Error: Incorrect value[DDD] for field[status]"]}
      end

      it "returns 400 status with error message when campaign campaign_type is invalid" do
        json_updated_campaign = instantiate_campaign(ref, invalid_campaign_type)
        put "/campaigns/#{ref}", json_updated_campaign
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors" => ["Campaign Error: Incorrect value[xyz] for field[campaign_type]"]}
      end

      it "returns 400 status with error message when campaign moh is invalid" do
        pending "Waiting for DIAL-470 to be resolved"
        json_updated_campaign = instantiate_campaign(ref, invalid_moh)
        put "/campaigns/#{ref}", json_updated_campaign
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors" => ["Campaign Error: Incorrect value[xyz] for field[moh]"]}
      end

      it "returns 400 status with error message when campaign agent_moh is invalid" do
        pending "Waiting for DIAL-470 to be resolved"
        json_updated_campaign = instantiate_campaign(ref, invalid_agent_moh)
        put "/campaigns/#{ref}", json_updated_campaign
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors" => ["Campaign Error: Incorrect value[xyz] for field[agent_moh]"]}
      end
    end

  end


  describe "Campaign deletion" do
    context "Success case" do
      let (:ref) { "#{Time.now.nsec.to_i}" }
      it 'deletes a specific campaign.' do
        create_campaign(ref)
        lambda do
          delete "/campaigns/#{ref}"
        end.should change(Campaign, :count).by(-1)
        last_response.status.should == 200
      end
    end

    context "Failure cases" do
      let!(:ref) { "#{Time.now.nsec.to_i}" }
      it 'returns status 404 and error message' do
        lambda do
          delete "/campaigns/#{ref}"
        end.should_not change(Campaign, :count)
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"errors" => ["Campaign Error: Campaign[#{ref}] does not exist"]}
      end
    end
  end


  describe "Retrieving a single campaign" do
    context "Success case" do
      let (:ref) { "#{Time.now.nsec.to_i}" }
      it 'retrieves a specific campaign.' do
        create_campaign(ref)
        get "/campaigns/#{ref}"
        JSON.parse(last_response.body)["campaign"].should include("campaign_ref" => ref)
        last_response.status.should == 200
      end
    end

    context "Failure cases" do
      let!(:ref) { "#{Time.now.nsec.to_i}" }
      it 'returns status 404 and error message' do
        get "/campaigns/#{ref}"
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"errors" => ["Campaign Error: Campaign[#{ref}] does not exist"]}
      end
    end
  end

  describe "List all campaign" do

    context "Success case" do
      it "returns 200 status and a list of campaigns" do
        get "/campaigns"
        last_response.status.should == 200
        last_response.body.should_not be_nil
      end
    end

    context "Failure cases" do
      #TODO I don't see what kind of validation could go here, event in the Apiary doc there is no validation for this case
    end

  end


end
