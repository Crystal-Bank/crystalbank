require "../../../spec_helper"

describe CrystalBank::Domains::Accounts::Aggregates::Concerns::Opening do
  describe "#apply" do
    it "Properly populates the aggregate on account opening" do
      actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")
      currencies = ["eur", "usd"].map { |c| CrystalBank::Types::Currencies::Supported.parse(c) }
      customer_ids = [UUID.new("00000000-0000-0000-0000-200000000001"), UUID.new("00000000-0000-0000-0000-200000000002")]
      scope_id = UUID.new("00000000-0000-0000-0000-300000000001")
      type = CrystalBank::Types::Accounts::Type.parse("checking")

      aggregate = Accounts::Aggregate.new(aggregate_id)

      # Opening request
      event_1 = Accounts::Opening::Events::Requested.new(
        actor_id: actor_id,
        command_handler: "test",
        currencies: currencies,
        customer_ids: customer_ids,
        scope_id: scope_id,
        type: type
      )
      aggregate.apply(event_1)

      # Accepted
      event_2 = Accounts::Opening::Events::Accepted.new(
        actor_id: nil,
        aggregate_id: aggregate_id,
        aggregate_version: aggregate.state.aggregate_version + 1,
        command_handler: "test"
      )
      aggregate.apply(event_2)

      state = aggregate.state
      state.aggregate_id.should eq(aggregate_id)
      state.aggregate_version.should eq(2)
      state.supported_currencies.should eq(currencies)
      state.type.should eq(type)
    end
  end
end
