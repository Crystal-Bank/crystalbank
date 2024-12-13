require "../../spec_helper"

describe CrystalBank::Api::JWT do
  it "should initialize correctly" do
    roles = [UUID.random]
    user_id = UUID.random
    payload = CrystalBank::Api::JWT.new(roles, user_id)

    payload.exp.should_not be_nil
    payload.iat.should_not be_nil
    payload.iss.should eq("CrystalBank")
    payload.jti.should_not be_nil
    payload.data.should_not be_nil
    payload.data.roles.should eq(roles)
    payload.data.user.should eq(user_id)
  end
end
