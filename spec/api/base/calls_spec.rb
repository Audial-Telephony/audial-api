require 'spec_helper'
require_relative File.dirname(__FILE__) + '/../../../models/cdr'
require_relative File.dirname(__FILE__) + '/../../../spec/factories/campains_factory'
require_relative File.dirname(__FILE__) + '/../../../spec/factories/calls_factory'
include CampainsFactory
include CallsFactory

describe Dialer::App do
  include Rack::Test::Methods

  def app
   @app =  Dialer::App.new
  end

  ################### specs #################

  describe "HTTPs call status" do

    context "Successfull Call creation" do
        it 'returns 201 when a call is created successfully' do
          response = JSON.parse(create_campaign("#{Time.now.nsec.to_i}").body)
          json_new_call = {call: {campaign_ref: response["campaign"]["campaign_ref"],  number: 1234567} }
          post "/calls" , json_new_call
          last_response.status.should == 201
          JSON.parse(last_response.body)["call"].should include("number_dialed"=>"1234567")
        end
    end

    context "Error in Call creation" do
      let! (:campaign_ref)  {Time.now.nsec.to_i}
      let!(:json_new_call) { {call: {campaign_ref: campaign_ref,  number: Time.now.nsec.to_i} }}
      let!(:json_new_call_missing_campaign_ref) { {call: { number: Time.now.nsec.to_i} }}
      let!(:json_new_call_missing_number) { {call: {campaign_ref: campaign_ref}}}
      let!(:json_new_call_missing_call_node) { {}}
      let!(:json_new_call_invalid) { {call: {campaign_ref: campaign_ref,number: Time.now.nsec.to_i,}}}

      it 'returns 404  when campaign_ref not found and no old CDR found' do
        post "/calls" , json_new_call
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"errors"=>["Campaign Error: Campaign[#{json_new_call[:call][:campaign_ref]}] does not exist"]}
      end

      it 'returns 400 (Bad request) when missing campaign_ref from the payload' do
        post "/calls" , json_new_call_missing_campaign_ref
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors"=>["call[campaign_ref] is missing"]}
      end

      it 'returns 400 (Bad request) when missing number from the payload' do
        post "/calls" , json_new_call_missing_number
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors"=>["call[number] is missing"]}
      end

      it 'returns 400 (Bad request) when call node is missing from the payload' do
        post "/calls" , json_new_call_missing_call_node
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors"=>["call is missing", "call[campaign_ref] is missing", "call[number] is missing"]}
      end

    end

    context "Successfull Call update" do
      let!(:campaign_creation_response) {JSON.parse(create_campaign("#{Time.now.nsec.to_i}").body)}
      let! (:response_call_creation) {JSON.parse(create_call(campaign_creation_response["campaign"]["campaign_ref"],"#{Time.now.nsec.to_i}").body) }

      it 'returns 200 when a call is updated successfully' do
        json_update_disposition = { call: { disposition: "E"}}
        put "/calls/#{response_call_creation["call"]["call_id"]}" , json_update_disposition
        last_response.status.should == 200

      end
    end

    context "Error in Call update" do
      let!(:campaign_creation_response) {JSON.parse(create_campaign("#{Time.now.nsec.to_i}").body)}
      let! (:response_call_creation) {JSON.parse(create_call(campaign_creation_response["campaign"]["campaign_ref"],"#{Time.now.nsec.to_i}").body) }

      it 'retuns 404 when the call_id is not found ' do
         json_update_disposition = { call: { disposition: "E"}}
        put "/calls/123998877" , json_update_disposition
        last_response.status.should == 404
         JSON.parse(last_response.body).should == {"errors"=>["Call Error: Call ID[123998877] does not exist"]}
      end

      it 'retuns 400 when the disposition code is not valid ' do
        json_update_disposition = { call: { disposition: "X"}}
        put "/calls/123998877" , json_update_disposition
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors"=>["Call Error: Invalid Disposition[X]"]}
      end

      it 'returns 400 when payload empty ' do
        json_update_disposition = { }
        put "/calls/#{response_call_creation["call"]["call_id"]}" , json_update_disposition
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors"=>["call is missing", "call[disposition] is missing"]}
      end

      it 'returns 400 when disposition is missing from the payload' do
        json_update_disposition = { call: { }}
        put "/calls/#{response_call_creation["call"]["call_id"]}" , json_update_disposition
        last_response.status.should == 400
        JSON.parse(last_response.body).should == {"errors"=>["call is missing", "call[disposition] is missing"]}
      end
    end


    describe "Recording" do
      let!(:campaign_creation_response) {JSON.parse(create_campaign("#{Time.now.nsec.to_i}").body)}
      let! (:response_call_creation) {JSON.parse(create_call(campaign_creation_response["campaign"]["campaign_ref"],"#{Time.now.nsec.to_i}").body) }
      let!(:call) { CDR.new}
      let(:file_to_read) { double('File') }

      context "Recording found" do

        it "reads successfully the file" do
          x = CDR[ id: response_call_creation["call"]["call_id"] ]
          x.update({recording_url: "spec/data/RING.WAV"}) #add a recording url by updating the new created call
          File.should_receive(:open).with("spec/data/RING.WAV").and_return(file_to_read) # the endpoint should open then file
          file_to_read.should_receive(:read) # the endpoint should ready the file
          get "/calls/recording/#{response_call_creation["call"]["call_id"]}"
          last_response.status.should == 200
        end
      end

      context "Recording not found" do
        it ' returns 404 when recording files not found' do
          get "/calls/recording/#{response_call_creation["call"]["call_id"]}"
          last_response.status.should == 404
         JSON.parse(last_response.body).should == {"errors"=>["Call Error: Recording not found"]}
        end

        it 'returns 404 when call_id is not found' do
          call_id = "#{Time.now.nsec.to_i}"
          get "/calls/recording/#{call_id}"
          last_response.status.should == 404
          JSON.parse(last_response.body).should == {"errors"=>["Call Error: Call ID[#{call_id}] does not exist"]}
        end
       end
    end
  end
end
