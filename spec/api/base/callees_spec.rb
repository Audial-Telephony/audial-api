require 'spec_helper'
require_relative File.dirname(__FILE__) + '/../../../models/callee'
require_relative File.dirname(__FILE__) + '/../../../spec/factories/campains_factory'
require_relative File.dirname(__FILE__) + '/../../../spec/factories/callees_factory'
include CampainsFactory
include CalleesFactory
describe Dialer::App do
  include Rack::Test::Methods

  def app
    Dialer::App.new
  end

  ################### specs #################

  describe "Successfull Callee creation" do
    let!(:ref) {"#{Time.now.nsec.to_i}"}
    let! (:contact_ref) { {callee: {contact_ref: ref, numbers: [n: "27974747474", p: 2]}}}

    it 'creates a callee, and return 201 status' do
        lambda do
          create_callee(ref, contact_ref)
        end.should change(Callee, :count).by(1)
        last_response.status.should == 201
        JSON.parse(last_response.body)["callee"].should include("campaign_ref"=>ref)
    end
  end

  describe "Error in Callee creation" do
    let!(:ref) {"#{Time.now.nsec.to_i}"}
    let!(:ref_2) {"#{Time.now.nsec.to_i}"}

    context "When contact_ref has been used before in another campaign" do
      let! (:contact_ref) { {callee: {contact_ref: Time.now.nsec.to_i, numbers: [n: "0111111111", p: 2]}}}
      it "returns 409 status and error message" do
        create_callee(ref, contact_ref)
        lambda do
          create_callee(ref_2, contact_ref)
        end.should_not change(Callee, :count)
        last_response.status.should == 409
        JSON.parse(last_response.body).should ==  {"errors"=>["Callee Error: Duplicate Contact Ref[#{contact_ref[:callee][:contact_ref]}]"]}
      end
    end

    context "When providing an invalid number" do

     context "when does not start with 0 or 27" do
       let!(:ref) {"#{Time.now.nsec.to_i}"}
       let! (:contact_ref) { {callee: {contact_ref: Time.now.nsec.to_i, numbers: [n: "24793547474", p: 2]}}}
       let! (:contact_ref_2) { {callee: {contact_ref: Time.now.nsec.to_i, numbers: [n: "9793547474", p: 2]}}}

       it"returns 400 and error message if number does not start with 27" do
          lambda do
            create_callee(ref, contact_ref)
          end.should_not change(Callee, :count)
          last_response.status.should == 400
          JSON.parse(last_response.body).should ==  {"errors"=>["Callee Error: Invalid number[24793547474] for Contact Contact Ref[#{contact_ref[:callee][:contact_ref]}]"]}
       end

       it"returns 400 and error message if phone does not start with 0" do
         lambda do
           create_callee(ref, contact_ref_2)
         end.should_not change(Callee, :count)
         last_response.status.should == 400
         JSON.parse(last_response.body).should ==  {"errors"=>["Callee Error: Invalid number[9793547474] for Contact Contact Ref[#{contact_ref_2[:callee][:contact_ref]}]"]}

       end
     end

     context "when starts with 0 or 27 but less than 9 digits" do
       let!(:ref) {"#{Time.now.nsec.to_i}"}
       let! (:contact_ref) { {callee: {contact_ref: Time.now.nsec.to_i, numbers: [n: "2779354747", p: 2]}}}
       let! (:contact_ref_2) { {callee: {contact_ref: Time.now.nsec.to_i, numbers: [n: "079354747", p: 2]}}}

       it"returns 400 and error message if number starts with 27" do
         lambda do
           create_callee(ref, contact_ref)
         end.should_not change(Callee, :count)
         last_response.status.should == 400
         JSON.parse(last_response.body).should ==  {"errors"=>["Callee Error: Invalid number[2779354747] for Contact Contact Ref[#{contact_ref[:callee][:contact_ref]}]"]}
       end

       it"returns 400 and error message if number starts with 0" do
         lambda do
           create_callee(ref, contact_ref_2)
         end.should_not change(Callee, :count)
         last_response.status.should == 400
         JSON.parse(last_response.body).should ==  {"errors"=>["Callee Error: Invalid number[079354747] for Contact Contact Ref[#{contact_ref_2[:callee][:contact_ref]}]"]}
       end
     end
    end

    context "When providing an invalid priority" do

        let! (:contact_ref) { {callee: {contact_ref: Time.now.nsec.to_i, numbers: [n: "27111111111", p: -5]}}}
        let! (:contact_ref_1) { {callee: {contact_ref: Time.now.nsec.to_i, numbers:[{n:"0123456789",p: -6}, {n:"27111111111",p: 3}]}}}
        let! (:contact_ref_2) { {callee: {contact_ref: Time.now.nsec.to_i, numbers:[{n:"0123456789",p: -7}, {n:"27111111111",p: 0}]}}}

        it 'returns status 400 with error message' do
          lambda do
            create_callee(ref_2, contact_ref)
          end.should_not change(Callee, :count)
          last_response.status.should == 400
          JSON.parse(last_response.body).should  ==  {"errors"=>["Callee Error: Invalid priority[-5] number[27111111111] for Contact Ref[#{contact_ref[:callee][:contact_ref]}]"]}

        end


        it 'returns status 400 with appropriate error message when one priority at least is not valid' do
          lambda do
            create_callee(ref_2, contact_ref_1)
          end.should_not change(Callee, :count)
          last_response.status.should == 400
          JSON.parse(last_response.body).should  ==  {"errors"=>["Callee Error: Invalid priority[-6] number[0123456789] for Contact Ref[#{contact_ref_1[:callee][:contact_ref]}]"]}

        end

        it 'returns status 400 with appropriate error message when all priorities are not valid' do
          lambda do
            create_callee(ref_2, contact_ref_2)
          end.should_not change(Callee, :count)
          last_response.status.should == 400
          JSON.parse(last_response.body).should  ==  {"errors"=>["Callee Error: Invalid priority[-7,0] number[0123456789,27111111111] for Contact Ref[#{contact_ref_2[:callee][:contact_ref]}]"]}

        end
    end


    context "When contact_ref is not valid" do
        let!(:ref) {"#{Time.now.nsec.to_i}"}
        let! (:contact_ref) { {callee: {contact_ref: "#{ref}%PP"}}}

        it ' does not create a callee, and return 400 status' do
          lambda do
            create_callee(ref, contact_ref)
          end.should_not change(Callee, :count)
          last_response.status.should == 400
          JSON.parse(last_response.body).should  ==  {"errors"=>["Callee Error: Invalid Contact ref[#{ref}%PP]"]}
        end
    end

    context "When missing contact_ref" do
      let!(:ref) {"#{Time.now.nsec.to_i}"}
      let! (:contact_ref) { {callee: {numbers: [n: "27974747474", p: 2]}}}

      it 'does not create a callee, and return 400 status' do
        lambda do
          create_callee(ref, contact_ref)
        end.should_not change(Callee, :count)
        last_response.status.should == 400
        JSON.parse(last_response.body).should  ==  {"errors"=>["Callee Error: Missing field[contact_ref]"]}
      end
    end

    context "When campaign does not exist" do
      let!(:ref) {"#{Time.now.nsec.to_i}"}

      it 'creates a callee, and return 400 status with error message' do
        contact = { callee: { campaign_ref: "123123" , contact_ref: ref, numbers: [n: "27974747474", p: 2]}}
        post "/callees", contact
        last_response.status.should == 404
        JSON.parse(last_response.body).should  ==  {"errors"=>["Campaign Error: Campaign[123123] does not exist"]}
      end
    end
  end



  describe "Successfull Callee modification" do

       context "when priority is different from -1 it adds the callee number to the campaign" do
         let!(:ref) {"#{Time.now.nsec.to_i}"}
         let! (:contact_r) { {callee: {contact_ref: ref, numbers: [n: "27999999999", p: 2]}}}

         it 'returns status 200 and update the number and priority' do
            create_callee(ref, contact_r)
            json_updated_callee = {callee: { numbers:[{n:"0433877777",p: 1}]} }
            put "/callees/#{ref}" , json_updated_callee
            last_response.status.should == 200
            get "/callees/#{ref}"
            JSON.parse(last_response.body)["callee"]["numbers"].should include("0433877777")
         end
       end

       context "when priority is -1 it remove the callee number from the campaign" do
         let!(:ref) {"#{Time.now.nsec.to_i}"}
         let! (:contact_r) { {callee: {contact_ref: ref, numbers: [n: "0338777779", p: 2]}}}

         it 'returns status 200 and update the number and priority' do
           create_callee(ref, contact_r)
           json_updated_callee = {callee: { numbers:[{n:"0338777779",p: -1}]} }
           put "/callees/#{ref}" , json_updated_callee
           last_response.status.should == 200
           get "/callees/#{ref}"
           JSON.parse(last_response.body)["callee"]["numbers"].should_not include("0338777779")
         end
       end
  end

  describe "Error in Callee modification" do

    context "priority not -1, or [1, +infinite]" do
      let!(:ref) {"#{Time.now.nsec.to_i}"}
      let! (:contact_ref) { {callee: {contact_ref: ref, numbers: [n: "0338777779", p: 2]}}}

      it 'returns status 400 with error message' do
        create_callee(ref, contact_ref)
        json_updated_callee = {callee: { numbers:[{n:"0338777759",p: -3}]} }
        put "/callees/#{ref}" , json_updated_callee
        last_response.status.should == 400
        JSON.parse(last_response.body).should  ==  {"errors"=>["Callee Error: Invalid priority[-3] number[0338777759] for Contact Ref[#{ref}]"]}
      end

      it 'returns status 400 with appropriate error message when one priority at least is not valid' do
        create_callee(ref, contact_ref)
        json_updated_callee = {callee: { numbers:[{n:"877777",p: -8}, {n:"9999999",p: 3}]} }
        put "/callees/#{ref}" , json_updated_callee
        last_response.status.should == 400
        JSON.parse(last_response.body).should  ==  {"errors"=>["Callee Error: Invalid priority[-8] number[877777] for Contact Ref[#{ref}]"]}
      end

      it 'returns status 400 with appropriate error message when all priorities are not valid' do
        create_callee(ref, contact_ref)
        json_updated_callee = {callee: { numbers:[{n:"877777",p: "e"}, {n:"9999999",p: 0}]} }
        put "/callees/#{ref}" , json_updated_callee
        last_response.status.should == 400
        JSON.parse(last_response.body).should  ==  {"errors"=>["Callee Error: Invalid priority[e,0] number[877777,9999999] for Contact Ref[#{ref}]"]}

      end
    end

    context "When providing an invalid number" do
      let!(:ref) {"#{Time.now.nsec.to_i}"}
      let! (:contact_ref) { {callee: {contact_ref: ref, numbers: [n: "0338777779", p: 2]}}}

      it 'returns status 400 with error message' do
        create_callee(ref, contact_ref)
        json_updated_callee = {callee: { numbers:[{n:"12345",p: 2}]} }
        put "/callees/#{ref}" , json_updated_callee
        last_response.status.should == 400
        JSON.parse(last_response.body).should ==  {"errors"=>["Callee Error: Invalid number[12345] for Contact Contact Ref[#{contact_ref[:callee][:contact_ref]}]"]}
      end
    end
  end

  describe "Successfull Callee deletion" do
    let!(:ref) {"#{Time.now.nsec.to_i}"}
    let! (:contact_ref) { {callee: {contact_ref: ref, numbers: [n: "0338777779", p: 2]}}}

    it 'deletes a specific caller and return status 200' do
      create_callee(ref, contact_ref)
      lambda do
        delete "/callees/#{ref}"
      end.should change(Callee, :count).by(-1)
      last_response.status.should == 200
    end
  end

  describe "Error in Callee deletion" do

    context "When contact_ref is not found" do
      let!(:ref) {"#{Time.now.nsec.to_i}"}

      it 'returns status 404 and error message' do
        create_callee(ref)
        lambda do
          delete "/callees/1234"
        end.should_not change(Callee, :count)
        last_response.status.should == 404
        JSON.parse(last_response.body).should ==  {"errors"=>["Callee Error: Contact Ref[1234] does not exist"]}
      end
    end
  end

  describe "Retrieving a callee" do
    let!(:ref) {"#{Time.now.nsec.to_i}"}
    let!(:numbers) {[n: "0338777779", p: 2]}
    let! (:contact_ref) { {callee: {contact_ref: ref, numbers: numbers}}}

    context "When the callee exists" do
        it 'returns 200 status and the callee information' do
          create_callee(ref, contact_ref)
          get "/callees/#{ref}"
          last_response.status.should == 200
          callee = JSON.parse(last_response.body)["callee"]
          callee.should include(
                                  "campaign_ref" => ref,
                                  "contact_ref" => ref,
                                  "status" => "pending",
                                  "dial_attempts" => 0,
                                  "calls" => []
                        )
          callee.should include("last_dialed_at", "numbers")
          callee["numbers"].should include("0338777779")
        end
    end

    context "When the callee does not exist" do
      it 'returns 404 status and an error message' do
        create_callee(ref)
        get "/callees/4545"
        last_response.status.should == 404
        JSON.parse(last_response.body).should ==  {"errors"=>["Callee Error: Contact Ref[4545] does not exist"]}
      end
    end
  end
end
