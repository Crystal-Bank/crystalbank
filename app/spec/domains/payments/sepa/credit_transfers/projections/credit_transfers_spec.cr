require "../../../../../spec_helper"
require "../events/initiation/requested_spec"
require "../events/initiation/accepted_spec"

describe CrystalBank::Domains::Payments::Sepa::CreditTransfers::Projections::CreditTransfers do
  it "inserts a row in 'pending' status when a Requested event is applied" do
    projection = Payments::Sepa::CreditTransfers::Projections::CreditTransfers.new
    uuid = UUID.v7

    event = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Requested.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event)
    projection.apply(event)

    count = TEST_PROJECTION_DB.scalar(
      %(SELECT count(*) FROM "projections"."sepa_credit_transfers" WHERE uuid = $1),
      uuid
    )
    count.should eq(1)

    status = TEST_PROJECTION_DB.scalar(
      %(SELECT status FROM "projections"."sepa_credit_transfers" WHERE uuid = $1),
      uuid
    )
    status.should eq("pending")
  end

  it "updates status to 'accepted' and sets ledger_transaction_id when an Accepted event is applied" do
    projection = Payments::Sepa::CreditTransfers::Projections::CreditTransfers.new
    uuid = UUID.v7

    event_1 = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Requested.new.create(aggr_id: uuid)
    event_2 = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Accepted.new.create(aggr_id: uuid)

    TEST_EVENT_STORE.append(event_1)
    TEST_EVENT_STORE.append(event_2)

    projection.apply(event_1)
    projection.apply(event_2)

    status = TEST_PROJECTION_DB.scalar(
      %(SELECT status FROM "projections"."sepa_credit_transfers" WHERE uuid = $1),
      uuid
    )
    status.should eq("accepted")

    ledger_tx_id = TEST_PROJECTION_DB.scalar(
      %(SELECT ledger_transaction_id FROM "projections"."sepa_credit_transfers" WHERE uuid = $1),
      uuid
    )
    ledger_tx_id.should eq(Test::Payments::Sepa::CreditTransfers::Events::LEDGER_TX_ID)
  end

  it "stores the correct payment fields from the Requested event" do
    projection = Payments::Sepa::CreditTransfers::Projections::CreditTransfers.new
    uuid = UUID.v7

    event = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Requested.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event)
    projection.apply(event)

    row = TEST_PROJECTION_DB.query_one(
      %(SELECT end_to_end_id, creditor_iban, creditor_name, amount, currency FROM "projections"."sepa_credit_transfers" WHERE uuid = $1),
      uuid,
      as: {String, String, String, Int64, String}
    )

    row[0].should eq("E2E-TEST-001")
    row[1].should eq("DE89370400440532013000")
    row[2].should eq("Test Creditor GmbH")
    row[3].should eq(10000_i64)
    row[4].should eq("EUR")
  end
end
