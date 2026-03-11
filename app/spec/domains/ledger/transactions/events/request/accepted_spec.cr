require "../../../../../spec_helper"

describe CrystalBank::Domains::Ledger::Transactions::Request::Events::Accepted do
  it "can be initialized" do
    event = Test::Ledger::Transactions::Events::Request::Accepted.new.create

    event.header.actor_id.should eq(UUID.new("00000000-0000-0000-0000-000000000000"))
    event.header.aggregate_id.should eq(UUID.new("00000000-0000-0000-0000-000000000001"))
    event.header.aggregate_type.should eq("LedgerTransaction")
    event.header.aggregate_version.should eq(2)
    event.header.command_handler.should eq("test")
    event.header.event_handle.should eq("ledger.transactions.request.accepted")
  end

  it "can be initialized from json" do
    object = Test::Ledger::Transactions::Events::Request::Accepted.new
    event = object.create
    h = event.header

    json_body = JSON.parse(object.json_string)

    e = Ledger::Transactions::Request::Events::Accepted.new(h, json_body)
    e.body.to_json.should eq(object.json_string)
  end

  it "can serialize and deserialize from json" do
    event = Test::Ledger::Transactions::Events::Request::Accepted.new.create
    h = event.header

    json_body = event.body.to_json

    e = Ledger::Transactions::Request::Events::Accepted.new(h, JSON.parse(json_body))
    json_body.should eq(e.body.to_json)
  end
end
