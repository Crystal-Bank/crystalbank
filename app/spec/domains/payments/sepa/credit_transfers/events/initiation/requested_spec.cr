require "../../../../../../spec_helper"

describe CrystalBank::Domains::Payments::Sepa::CreditTransfers::Initiation::Events::Requested do
  it "can be initialized" do
    event = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Requested.new.create

    event.header.actor_id.should eq(UUID.new("00000000-0000-0000-0000-000000000000"))
    event.header.aggregate_id.should eq(UUID.new("00000000-0000-0000-0000-000000000001"))
    event.header.aggregate_type.should eq("Payments.Sepa.CreditTransfer")
    event.header.aggregate_version.should eq(1)
    event.header.command_handler.should eq("test")
    event.header.event_handle.should eq("payments.sepa.credit_transfers.initiation.requested")

    body = event.body.as(Payments::Sepa::CreditTransfers::Initiation::Events::Requested::Body)
    body.end_to_end_id.should eq("E2E-TEST-001")
    body.debtor_account_id.should eq(Test::Payments::Sepa::CreditTransfers::Events::DEBTOR_ACCOUNT_ID)
    body.creditor_iban.should eq("DE89370400440532013000")
    body.creditor_name.should eq("Test Creditor GmbH")
    body.creditor_bic.should be_nil
    body.amount.should eq(10000_i64)
    body.remittance_information.should eq("Test payment")
    body.scope_id.should eq(Test::Payments::Sepa::CreditTransfers::Events::SCOPE_ID)
  end

  it "can be initialized from json" do
    object = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Requested.new
    event = object.create
    h = event.header

    json_body = JSON.parse(object.json_string)
    e = Payments::Sepa::CreditTransfers::Initiation::Events::Requested.new(h, json_body)
    b = e.body.as(Payments::Sepa::CreditTransfers::Initiation::Events::Requested::Body)

    b.end_to_end_id.should eq("E2E-TEST-001")
    b.amount.should eq(10000_i64)
  end

  it "can serialize and deserialize from json" do
    event = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Requested.new.create
    h = event.header

    b = event.body.as(Payments::Sepa::CreditTransfers::Initiation::Events::Requested::Body)
    json_body = b.to_json

    e = Payments::Sepa::CreditTransfers::Initiation::Events::Requested.new(h, JSON.parse(json_body))
    json_body.should eq(e.body.to_json)
  end
end
