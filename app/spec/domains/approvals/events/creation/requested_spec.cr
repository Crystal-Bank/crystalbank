require "../../../../spec_helper"

describe CrystalBank::Domains::Approvals::Creation::Events::Requested do
  it "can be initialized" do
    event = Test::Approval::Events::Creation::Requested.new.create

    event.header.actor_id.should eq(UUID.new("00000000-0000-0000-0000-000000000000"))
    event.header.aggregate_id.should eq(UUID.new("00000000-0000-0000-0000-000000000001"))
    event.header.aggregate_type.should eq("Approval")
    event.header.command_handler.should eq("test")
    event.header.event_handle.should eq("approval.creation.requested")
    event.body.comment.should eq("test comment")
  end

  it "can be initialized from json" do
    object = Test::Approval::Events::Creation::Requested.new
    event = object.create
    h = event.header

    json_body = JSON.parse(object.json_string)

    e = Approvals::Creation::Events::Requested.new(h, json_body)
    b = e.body.as(Approvals::Creation::Events::Requested::Body)

    b.scope_id.should eq(UUID.new("00000000-0000-0000-0000-100000000001"))
    b.source_aggregate_type.should eq("Account")
    b.source_aggregate_id.should eq(UUID.new("00000000-0000-0000-0000-200000000001"))
    b.required_approvals.should eq(["write_accounts_opening_compliance_approval", "write_accounts_opening_board_approval"])
  end

  it "can serialize to json" do
    object = Test::Approval::Events::Creation::Requested.new
    event = object.create

    b = event.body.as(Approvals::Creation::Events::Requested::Body)
    b.to_json.should eq(object.json_string)
  end

  it "can serialize and deserialize from json" do
    event = Test::Approval::Events::Creation::Requested.new.create
    h = event.header

    b = event.body.as(Approvals::Creation::Events::Requested::Body)
    json_body = b.to_json

    e = Approvals::Creation::Events::Requested.new(h, JSON.parse(json_body))
    json_body.should eq(e.body.to_json)
  end
end
