require 'spec_helper'
require_relative File.dirname(__FILE__) + '/../../models/agent'

describe Agent do

  #--1 -- invalid data

  it "extension is required, nil value not accepted" do
     ag = Agent.new({extension: nil})
     ag.valid?.should be_false

  end

  it "extension is required blank value bot accepted" do
    ag = Agent.new({extension: ''})
    ag.valid?.should be_false

  end

  it "Status is required and should be available, away, busy or offline" do
    pending "Is this test still correct? The implementation is commented out"
    ag = Agent.new ({extension: 1234, status: "xyz"})
    ag.valid?.should be_false
  end


  it "Status is required and should not be null" do
    pending "Is this test still correct? The implementation is commented out"
    ag = Agent.new ({extension: 1234, status: nil})
    ag.valid?.should be_false
  end

  it "Status is required and should not be empty" do
    pending "Is this test still correct? The implementation is commented out"
    ag = Agent.new ({extension: 1234, status: ''})
    ag.valid?.should be_false
  end

  # --2  --- Valid data
  it "should return true when a value is entered for the extension" do
    ag = Agent.new({extension: 1234})
    ag.valid?.should be_true

  end

  it "Should return true when 'busy' is entered as status" do
    ag = Agent.new ({extension: 1234, status: "busy"})
    ag.valid?.should be_true
  end

  it "Should return true when 'away' is entered as status" do
    ag = Agent.new ({extension: 1234, status: "away"})
    ag.valid?.should be_true
  end
  it "Should return true when 'available' is entered as status" do
    ag = Agent.new ({extension: 1234, status: "available"})
    ag.valid?.should be_true
  end

  it "Should return true when 'offline' is entered as status" do
    ag = Agent.new ({extension: 1234, status: "offline"})
    ag.valid?.should be_true
  end

end
