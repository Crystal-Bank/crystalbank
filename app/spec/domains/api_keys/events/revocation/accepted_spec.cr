require "../../../../spec_helper"

describe CrystalBank::Domains::ApiKeys::Revocation::Events::Accepted do
  it "can be initialized" do
    event = Test::ApiKey::Events::Revocation::Accepted.new.create(version: 2)

    event.header.actor_id.should eq(UUID.new("00000000-0000-0000-0000-000000000000"))
    event.header.aggregate_id.should eq(UUID.new("00000000-0000-0000-0000-000000000001"))
    event.header.aggregate_type.should eq("ApiKey")
    event.header.aggregate_version.should eq(2)
    event.header.command_handler.should eq("test")
    event.header.event_handle.should eq("api_key.revocation.accepted")
    event.body.comment.should eq("test comment")
  end

  it "can be initialized from json" do
    object = Test::ApiKey::Events::Revocation::Accepted.new
    event = object.create
    h = event.header

    json_body = JSON.parse(object.json_string)

    e = ApiKeys::Revocation::Events::Accepted.new(h, json_body)
    b = e.body.as(ApiKeys::Revocation::Events::Accepted::Body)

    b.comment.should eq("test comment")
  end

  it "can serialize to json" do
    object = Test::ApiKey::Events::Revocation::Accepted.new
    event = object.create

    b = event.body.as(ApiKeys::Revocation::Events::Accepted::Body)
    b.to_json.should eq(object.json_string)
  end

  it "can serialize and deserialize from json" do
    event = Test::ApiKey::Events::Revocation::Accepted.new.create
    h = event.header

    b = event.body.as(ApiKeys::Revocation::Events::Accepted::Body)
    json_body = b.to_json

    e = ApiKeys::Revocation::Events::Accepted.new(h, JSON.parse(json_body))
    json_body.should eq(e.body.to_json)
  end
end
