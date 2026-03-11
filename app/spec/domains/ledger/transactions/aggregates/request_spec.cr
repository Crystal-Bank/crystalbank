require "../../../../spec_helper"

describe CrystalBank::Domains::Ledger::Transactions::Aggregates::Concerns::Request do
  describe "#apply" do
    it "populates aggregate state on ledger.transactions.request.requested event" do
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")
      scope_id = UUID.new("00000000-0000-0000-0000-100000000001")

      aggregate = Ledger::Transactions::Aggregate.new(aggregate_id)

      event = Test::Ledger::Transactions::Events::Request::Requested.new.create(aggr_id: aggregate_id)
      aggregate.apply(event)

      state = aggregate.state
      state.aggregate_id.should eq(aggregate_id)
      state.aggregate_version.should eq(1)
      state.currency.should eq(CrystalBank::Types::Currencies::Supported::EUR)
      state.remittance_information.should eq("test remittance information")
      state.scope_id.should eq(scope_id)
      state.entries.should_not eq(nil)
      state.entries.not_nil!.size.should eq(2)
    end

    it "advances version on ledger.transactions.request.accepted event" do
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")

      aggregate = Ledger::Transactions::Aggregate.new(aggregate_id)

      event_1 = Test::Ledger::Transactions::Events::Request::Requested.new.create(aggr_id: aggregate_id)
      aggregate.apply(event_1)

      event_2 = Test::Ledger::Transactions::Events::Request::Accepted.new.create(aggr_id: aggregate_id)
      aggregate.apply(event_2)

      aggregate.state.aggregate_version.should eq(2)
    end
  end
end
