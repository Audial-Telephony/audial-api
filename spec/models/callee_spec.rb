require 'spec_helper'
require_relative File.dirname(__FILE__) + '/../../models/callee'

describe Callee do

  #--1 -- invalid data

  xit "numbers should be numeric" do
    #TODO to check with Lloyd  where is stored the number and priority
    ca = Callee.new({number: "abcnd"})
    ca.valid?.should be_false
  end

  it "Status is required and should be pending, complete, or dnc" do
    pending "Is this test still correct? The implementation is commented out"
    ca = Callee.new({status: "fdfd"})
    ca.valid?.should be_false
  end
  it "Status is required and should not be nil" do
    pending "Is this test still correct? The implementation is commented out"
    ca = Callee.new({status: nil})
    ca.valid?.should be_false
  end
  it "Status is required and should not be empty" do
    pending "Is this test still correct? The implementation is commented out"
    ca = Callee.new({status: ''})
    ca.valid?.should be_false
  end



  # --2  --- Valid data
  it "Return true if status = 'pending" do
    ca = Callee.new({contact_ref: 123 ,status: 'pending'})
    ca.valid?.should be_true
  end

  it "Return true if status = 'complete" do
    ca = Callee.new({contact_ref: 123 ,status: 'complete'})
    ca.valid?.should be_true
  end

  it "Return true if status = 'dnc" do
    ca = Callee.new({contact_ref: 123 ,status: 'dnc'})
    ca.valid?.should be_true
  end

end
