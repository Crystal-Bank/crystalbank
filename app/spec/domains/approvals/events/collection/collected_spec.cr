require "../../../../spec_helper"

describe CrystalBank::Domains::Approvals::Collection::Events::Collected do
  it "can be initialized" do
    event = Test::Approval::Events::Collection::Collected.new.create

    event.header.actor_id.should eq(UUID.new("00000000-0000-0000-0000-000000000000"))
    event.header.aggregate_id.should eq(UUID.new("00000000-0000-0000-0000-000000000001"))
    event.header.aggregate_type.should eq("Approval")
    event.header.aggregate_version.should eq(2)
    event.header.command_handler.should eq("test")
    event.header.event_handle.should eq("approval.collection.collected")
    event.body.comment.should eq("test comment")
  end

  it "can be initialized from json" do
    object = Test::Approval::Events::Collection::Collected.new
    event = object.create
    h = event.header

    json_body = JSON.parse(object.json_string)

    e = Approvals::Collection::Events::Collected.new(h, json_body)
    b = e.body.as(Approvals::Collection::Events::Collected::Body)

    b.user_id.should eq(UUID.new("00000000-0000-0000-0000-300000000001"))
    b.permissions.should eq(["write_accounts_opening_compliance_approval"])
    b.comment.should eq("test comment")
  end

  it "can serialize to json" do
    object = Test::Approval::Events::Collection::Collected.new
    event = object.create

    b = event.body.as(Approvals::Collection::Events::Collected::Body)
    b.to_json.should eq(object.json_string)
  end

  it "can serialize and deserialize from json" do
    event = Test::Approval::Events::Collection::Collected.new.create
    h = event.header

    b = event.body.as(Approvals::Collection::Events::Collected::Body)
    json_body = b.to_json

    e = Approvals::Collection::Events::Collected.new(h, JSON.parse(json_body))
    json_body.should eq(e.body.to_json)
  end
end
