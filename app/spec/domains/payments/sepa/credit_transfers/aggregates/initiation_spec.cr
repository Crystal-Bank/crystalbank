require "../../../../../spec_helper"

describe CrystalBank::Domains::Payments::Sepa::CreditTransfers::Aggregates::Concerns::Initiation do
  describe "#apply" do
    it "populates aggregate state on payments.sepa.credit_transfers.initiation.requested event" do
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")

      aggregate = Payments::Sepa::CreditTransfers::Aggregate.new(aggregate_id)
      event = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Requested.new.create(aggr_id: aggregate_id)
      aggregate.apply(event)

      state = aggregate.state
      state.aggregate_id.should eq(aggregate_id)
      state.aggregate_version.should eq(1)
      state.end_to_end_id.should eq("E2E-TEST-001")
      state.debtor_account_id.should eq(Test::Payments::Sepa::CreditTransfers::Events::DEBTOR_ACCOUNT_ID)
      state.settlement_account_id.should eq(Test::Payments::Sepa::CreditTransfers::Events::SETTLEMENT_ACCOUNT_ID)
      state.creditor_iban.should eq("DE89370400440532013000")
      state.creditor_name.should eq("Test Creditor GmbH")
      state.creditor_bic.should be_nil
      state.amount.should eq(10000_i64)
      state.remittance_information.should eq("Test payment")
      state.scope_id.should eq(Test::Payments::Sepa::CreditTransfers::Events::SCOPE_ID)
      state.status.should eq("pending")
      state.ledger_transaction_id.should be_nil
    end

    it "updates status and ledger_transaction_id on payments.sepa.credit_transfers.initiation.accepted event" do
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")

      aggregate = Payments::Sepa::CreditTransfers::Aggregate.new(aggregate_id)

      event_1 = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Requested.new.create(aggr_id: aggregate_id)
      aggregate.apply(event_1)

      event_2 = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Accepted.new.create(aggr_id: aggregate_id)
      aggregate.apply(event_2)

      state = aggregate.state
      state.aggregate_version.should eq(2)
      state.status.should eq("accepted")
      state.ledger_transaction_id.should eq(Test::Payments::Sepa::CreditTransfers::Events::LEDGER_TX_ID)
    end

    it "can be hydrated from the event store" do
      aggregate_id = UUID.v7

      event_1 = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Requested.new.create(aggr_id: aggregate_id)
      event_2 = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Accepted.new.create(aggr_id: aggregate_id)
      TEST_EVENT_STORE.append(event_1)
      TEST_EVENT_STORE.append(event_2)

      aggregate = Payments::Sepa::CreditTransfers::Aggregate.new(aggregate_id)
      aggregate.hydrate

      aggregate.state.status.should eq("accepted")
      aggregate.state.aggregate_version.should eq(2)
    end
  end
end
