require "../../../spec_helper"

describe CrystalBank::Domains::ApiKeys::Aggregates::Concerns::Revocation do
  describe "#apply" do
    it "Properly populates the aggregate on api key revocation" do
      actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")
      name = "Test key name"
      user_id = UUID.new("00000000-0000-0000-0000-200000000000")

      aggregate = ApiKeys::Aggregate.new(aggregate_id)

      # Revocation requested
      event_1 = ApiKeys::Revocation::Events::Requested.new(
        actor_id: actor_id,
        aggregate_id: aggregate_id,
        aggregate_version: aggregate.state.aggregate_version + 1,
        command_handler: "test",
        reason: "revocation reason"
      )
      aggregate.apply(event_1)

      # Revocation accepted
      event_2 = ApiKeys::Revocation::Events::Accepted.new(
        actor_id: nil,
        aggregate_id: aggregate_id,
        aggregate_version: aggregate.state.aggregate_version + 1,
        command_handler: "test"
      )
      aggregate.apply(event_2)

      state = aggregate.state
      state.aggregate_id.should eq(aggregate_id)
      state.aggregate_version.should eq(2)
      state.active.should eq(false)
      state.revoked_at.should_not be_nil
    end
  end
end
