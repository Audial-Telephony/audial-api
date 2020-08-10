require 'spec_helper'
require_relative File.dirname(__FILE__) + '/../../models/campaign'

describe Campaign do


  #name
  it "name is optional, empty value is valid" do
    cm = Campaign.new({name: '', ref: "123",status: "stopped"})
    cm.valid?.should be_true
  end

  it "name is optional, nil value is valid" do
    cm = Campaign.new({name: nil, ref: "123",status: "stopped"})
    cm.valid?.should be_true
  end
  it "name is optional, should not be longer than 50 characters" do
    cm = Campaign.new({name: "ab"*60, ref: "123",status: "stopped"})
    cm.valid?.should be_false
  end

  it "name is optional, should be less or  50 characters" do
    cm = Campaign.new({name: "a"*50, ref: "123",status: "stopped"})
    cm.valid?.should be_true
  end

  #ref
  it "Ref is required, nil value is not valid"   do
    cm = Campaign.new({ref: nil,status: "stopped"})
    cm.valid?.should be_false
  end

  it "Ref is required, empty value is not valid"   do
    cm = Campaign.new({ref: "",status: "stopped"})
    cm.valid?.should be_false
  end

  it "Ref is required, string value is valid"   do
    cm = Campaign.new({ref: "123|23",status: "stopped"})
    cm.valid?.should be_true
  end

  it "Status is required and should be started or stopped" do
    cm = Campaign.new({ref: "123|23",status: "fdfd"})
    cm.valid?.should be_false
  end

  it "Status is required and should not be nil" do
    cm = Campaign.new({ref: "123|23",status: nil})
    cm.valid?.should be_false
  end
  it "Status is required and should not be empty" do
    cm = Campaign.new({ref: "123|23",status: ""})
    cm.valid?.should be_false
  end

  it "Return true if status = 'stopped" do
    cm = Campaign.new({ref: "123|23",status: "stopped"})
    cm.valid?.should be_true
  end

  it "Return true if status = 'started" do
    cm = Campaign.new({ref: "123|23",status: "started"})
    cm.valid?.should be_true
  end

  it "Return true if status = 'stopped" do
    cm = Campaign.new({ref: "123|23",status: "stopped"})
    cm.valid?.should be_true
  end



end
