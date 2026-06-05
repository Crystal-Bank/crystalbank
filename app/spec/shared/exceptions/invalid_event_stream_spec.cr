require "../../spec_helper"

describe CrystalBank::Exception::InvalidEventStream do
  it "should initialize with a message" do
    exception = CrystalBank::Exception::InvalidEventStream.new("Test message")
    exception.message.should eq "Test message"
  end

  it "should initialize with a default message" do
    exception = CrystalBank::Exception::InvalidEventStream.new
    exception.message.should eq "Invalid event stream"
  end

  it "should initialize with a status code" do
    exception = CrystalBank::Exception::InvalidEventStream.new(status_code: HTTP::Status::BAD_REQUEST)
    exception.status_code.should eq HTTP::Status::BAD_REQUEST
  end

  it "should initialize with a default status code" do
    exception = CrystalBank::Exception::InvalidEventStream.new
    exception.status_code.should eq HTTP::Status::UNPROCESSABLE_ENTITY
  end
end
