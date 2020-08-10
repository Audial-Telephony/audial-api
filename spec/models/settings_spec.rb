require 'spec_helper'
require_relative File.dirname(__FILE__) + '/../../models/settings'

describe Callee do

  #--1 -- invalid data

  it "outbound_call_id is required, nil value not accepted" do

     se = Settings.new({outbound_call_id: nil})
     se.valid?.should be_false
  end


  it "outbound_call_id is required, empty value not accepted" do

    se = Settings.new({outbound_call_id: ""})
    se.valid?.should be_false
  end

  it "dial_from_self is optional, default is false" do

    se = Settings.new({outbound_call_id: "1234" })
    saved_obj = se.save
    #se.valid?.should be_true
    saved_obj.dial_from_self.should == false
  end

  it "dial_from_self is optional, if true provided, should return true" do

    se = Settings.new({outbound_call_id: "1234", dial_from_self: true })
    saved_obj = se.save
    saved_obj.dial_from_self.should == true
  end

  it "dial_from_self is optional, if false provided, should return false" do

    se = Settings.new({outbound_call_id: "1234", dial_from_self: false })
    saved_obj = se.save
    saved_obj.dial_from_self.should == false
  end

  # dial_aggression
  it "dial_aggression is optional, default to 3" do

    se = Settings.new({outbound_call_id: "1234" })
    saved_obj = se.save
    saved_obj.dial_aggression.should == 3
  end

  it "dial_aggression is optional, if provided shouldn't be greater than 10" do

    se = Settings.new({outbound_call_id: "1234", dial_aggression: 11 })
    se.valid?.should be_false
  end

  it "dial_aggression is optional, if provided shouldn't be less than 1" do
    se = Settings.new({outbound_call_id: "1234", dial_aggression: 0 })
    se.valid?.should be_false
  end
  it "dial_aggression is optional, if provided should be between 1 and 10" do
    se = Settings.new({outbound_call_id: "1234", dial_aggression: 1 })
    se.valid?.should be_true
  end

  # max_attempts
  it "max_attempts is optional, default to 30" do

    se = Settings.new({outbound_call_id: "1234" })
    saved_obj = se.save
    saved_obj.max_attempts.should == 30
  end

  it "max_attempts is optional, if provided shouldn't be greater than 255" do

    se = Settings.new({outbound_call_id: "1234", max_attempts: 256 })
    se.valid?.should be_false
  end

  it "max_attempts is optional, if provided shouldn't be less than 1" do
    se = Settings.new({outbound_call_id: "1234", max_attempts: 0 })
    se.valid?.should be_false
  end
  it "max_attempts is optional, if provided should be between 1 and 255" do
    se = Settings.new({outbound_call_id: "1234", max_attempts: 13 })
    se.valid?.should be_true
  end

   #hold_timeout: Integer
  it "hold_timeout is optional, default to 0" do

    se = Settings.new({outbound_call_id: "1234" })
    saved_obj = se.save
    saved_obj.hold_timeout.should == 0
  end

  it "hold_timeout is optional, if a value is provided, should return this value after save" do

    se = Settings.new({outbound_call_id: "1234", hold_timeout: 12 })
    saved_obj = se.save
    saved_obj.hold_timeout.should == 12
  end

  #call_timeout
  it "call_timeout is optional, default to 0" do

    se = Settings.new({outbound_call_id: "1234" })
    saved_obj = se.save
    saved_obj.call_timeout.should == 0
  end

  it "call_timeout is optional, if a value is provided, should return this value after save" do

    se = Settings.new({outbound_call_id: "1234", call_timeout: 11 })
    saved_obj = se.save
    saved_obj.call_timeout.should == 11
  end

  #wrapup_time
  it "wrapup_time is optional, default to 0" do

    se = Settings.new({outbound_call_id: "1234" })
    saved_obj = se.save
    saved_obj.wrapup_time.should == 0
  end

  it "wrapup_time is optional, if a value is provided, should return this value after save" do

    se = Settings.new({outbound_call_id: "1234", wrapup_time: 23 })
    saved_obj = se.save
    saved_obj.wrapup_time.should == 23
  end

  #retry_timeout
  it "retry_timeout is optional, default to 1800" do

    se = Settings.new({outbound_call_id: "1234" })
    saved_obj = se.save
    saved_obj.retry_timeout.should == 1800
  end

  it "retry_timeout is optional, if a value is provided, should return this value after save" do

    se = Settings.new({outbound_call_id: "1234", retry_timeout: 2000 })
    saved_obj = se.save
    saved_obj.retry_timeout.should == 2000
  end



end
