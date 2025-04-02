require "../../../spec_helper"

describe CrystalBank::Domains::Customers::Aggregates::Concerns::Onboarding do
  describe "#apply" do
    it "Properly populates the aggregate on customer onboarding" do
      actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")
      name = "Peter Pan"
      scope_id = UUID.new("00000000-0000-0000-0000-000000000002")
      type = CrystalBank::Types::Customers::Type.parse("individual")

      aggregate = Customers::Aggregate.new(aggregate_id)

      # Onboarding request
      event_1 = Customers::Onboarding::Events::Requested.new(
        actor_id: actor_id,
        command_handler: "test",
        name: name,
        scope_id: scope_id,
        type: type
      )
      aggregate.apply(event_1)

      # Accepted
      event_2 = Customers::Onboarding::Events::Accepted.new(
        actor_id: nil,
        aggregate_id: aggregate_id,
        aggregate_version: aggregate.state.aggregate_version + 1,
        command_handler: "test"
      )
      aggregate.apply(event_2)

      state = aggregate.state
      state.aggregate_id.should eq(aggregate_id)
      state.aggregate_version.should eq(2)
      state.name.should eq(name)
      state.type.should eq(type)
    end
  end
end
