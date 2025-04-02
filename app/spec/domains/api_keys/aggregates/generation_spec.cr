require "../../../spec_helper"

describe CrystalBank::Domains::ApiKeys::Aggregates::Concerns::Generation do
  describe "#apply" do
    it "Properly populates the aggregate on api key generation" do
      actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")
      name = "Test key name"
      scope_id = UUID.new("00000000-0000-0000-0000-000000000001")
      user_id = UUID.new("00000000-0000-0000-0000-200000000000")

      aggregate = ApiKeys::Aggregate.new(aggregate_id)

      # Generation request
      event_1 = ApiKeys::Generation::Events::Requested.new(
        actor_id: actor_id,
        api_secret: "secret",
        command_handler: "test",
        name: name,
        scope_id: scope_id,
        user_id: user_id
      )
      aggregate.apply(event_1)

      # Accepted
      event_2 = ApiKeys::Generation::Events::Accepted.new(
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
      state.user_id.should eq(user_id)
    end
  end
end
