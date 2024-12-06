require "../../../spec_helper"

describe CrystalBank::Domains::Users::Aggregates::Concerns::Onboarding do
  describe "#apply" do
    it "Properly populates the aggregate on account opening" do
      actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")
      name = "Test user"
      email = "test@crystalbank.xyz"

      aggregate = Users::Aggregate.new(aggregate_id)

      # Opening request
      event_1 = Users::Onboarding::Events::Requested.new(
        actor_id: actor_id,
        command_handler: "test",
        name: name,
        email: email
      )
      aggregate.apply(event_1)

      # Accepted
      event_2 = Users::Onboarding::Events::Accepted.new(
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
      state.email.should eq(email)
    end
  end
end
