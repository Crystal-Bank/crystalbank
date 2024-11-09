require "../../../../spec_helper"

describe CrystalBank::Domains::Transactions::InternalTransfers::Initiation do
  describe "#apply" do
    it "Properly populates the aggregate on internal transfer initiation" do
      actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")
      amount = 100
      creditor_account_id = UUID.new("00000000-0000-0000-0000-100000000000")
      currency = CrystalBank::Types::Currencies::Supported.parse("eur")
      debtor_account_id = UUID.new("00000000-0000-0000-0000-200000000000")

      aggregate = Transactions::InternalTransfers::Aggregate.new(aggregate_id)

      # Opening request
      event_1 = Transactions::InternalTransfers::Initiation::Events::Requested.new(
        actor_id: actor_id,
        amount: amount,
        command_handler: "test",
        creditor_account_id: creditor_account_id,
        currency: currency,
        debtor_account_id: debtor_account_id
      )
      aggregate.apply(event_1)

      # Accepted
      event_2 = Transactions::InternalTransfers::Initiation::Events::Accepted.new(
        actor_id: nil,
        aggregate_id: aggregate_id,
        aggregate_version: aggregate.state.aggregate_version + 1,
        command_handler: "test"
      )
      aggregate.apply(event_2)

      state = aggregate.state
      state.aggregate_id.should eq(aggregate_id)
      state.aggregate_version.should eq(2)
      state.currency.should eq(currency)
      state.debtor_account_id.should eq(debtor_account_id)
      state.creditor_account_id.should eq(creditor_account_id)
      state.amount.should eq(amount)
    end
  end
end
