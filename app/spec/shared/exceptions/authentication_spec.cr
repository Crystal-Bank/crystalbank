require "../../spec_helper"

describe CrystalBank::Exception::Authentication do
  it "should initialize with a message" do
    exception = CrystalBank::Exception::Authentication.new("Test message")
    exception.message.should eq "Test message"
  end

  it "should initialize with a default message" do
    exception = CrystalBank::Exception::Authentication.new
    exception.message.should eq "Authentication error"
  end

  it "should initialize with a status code" do
    exception = CrystalBank::Exception::Authentication.new(status_code: HTTP::Status::SERVICE_UNAVAILABLE)
    exception.status_code.should eq HTTP::Status::SERVICE_UNAVAILABLE
  end

  it "should initialize with a default status code" do
    exception = CrystalBank::Exception::Authentication.new
    exception.status_code.should eq HTTP::Status::BAD_REQUEST
  end
end
