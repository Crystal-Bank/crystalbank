require "../../../../../../spec_helper"

describe CrystalBank::Domains::Payments::Sepa::CreditTransfers::Initiation::Events::Accepted do
  it "can be initialized" do
    event = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Accepted.new.create

    event.header.actor_id.should eq(UUID.new("00000000-0000-0000-0000-000000000000"))
    event.header.aggregate_id.should eq(UUID.new("00000000-0000-0000-0000-000000000001"))
    event.header.aggregate_type.should eq("Payments.Sepa.CreditTransfer")
    event.header.aggregate_version.should eq(2)
    event.header.command_handler.should eq("test")
    event.header.event_handle.should eq("payments.sepa.credit_transfers.initiation.accepted")

    body = event.body.as(Payments::Sepa::CreditTransfers::Initiation::Events::Accepted::Body)
    body.ledger_transaction_id.should eq(Test::Payments::Sepa::CreditTransfers::Events::LEDGER_TX_ID)
  end

  it "can be initialized from json" do
    object = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Accepted.new
    event = object.create
    h = event.header

    json_body = JSON.parse(object.json_string)
    e = Payments::Sepa::CreditTransfers::Initiation::Events::Accepted.new(h, json_body)
    b = e.body.as(Payments::Sepa::CreditTransfers::Initiation::Events::Accepted::Body)

    b.ledger_transaction_id.should eq(Test::Payments::Sepa::CreditTransfers::Events::LEDGER_TX_ID)
  end

  it "can serialize and deserialize from json" do
    event = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Accepted.new.create
    h = event.header

    b = event.body.as(Payments::Sepa::CreditTransfers::Initiation::Events::Accepted::Body)
    json_body = b.to_json

    e = Payments::Sepa::CreditTransfers::Initiation::Events::Accepted.new(h, JSON.parse(json_body))
    json_body.should eq(e.body.to_json)
  end
end
