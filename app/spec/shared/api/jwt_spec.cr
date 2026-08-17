require "../../spec_helper"

describe CrystalBank::Api::JWT do
  it "should initialize correctly" do
    roles = [UUID.random]
    user_id = UUID.random
    payload = CrystalBank::Api::JWT.new(roles, user_id)

    payload.exp.should_not be_nil
    payload.iat.should_not be_nil
    payload.iss.should eq("https://api.crystalbank.xyz")
    payload.jti.should_not be_nil
    payload.data.should_not be_nil
    payload.data.roles.should eq(roles)
    payload.data.user.should eq(user_id)
  end

  it "sets sub equal to data.user" do
    roles = [UUID.random]
    user_id = UUID.random
    payload = CrystalBank::Api::JWT.new(roles, user_id)

    payload.sub.should eq(user_id)
    payload.sub.should eq(payload.data.user)
  end

  it "iss comes from the ISSUER env var default" do
    payload = CrystalBank::Api::JWT.new([UUID.random], UUID.random)
    payload.iss.should eq(CrystalBank::Env.issuer)
  end

  it "serialises with sub at the top level alongside data" do
    user_id = UUID.random
    payload = CrystalBank::Api::JWT.new([UUID.random], user_id)
    parsed = JSON.parse(payload.to_json)

    parsed["sub"].as_s.should eq(user_id.to_s)
    parsed["data"]["user"].as_s.should eq(user_id.to_s)
    parsed["data"]["roles"].as_a.should_not be_nil
    parsed["data"].as_h.keys.should_not contain("scope")
    parsed.as_h.keys.should_not contain("aud")
  end
end
