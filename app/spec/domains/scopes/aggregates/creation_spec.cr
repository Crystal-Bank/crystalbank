require "../../../spec_helper"

describe CrystalBank::Domains::Scopes::Aggregates::Concerns::Creation do
  describe "#apply" do
    it "Properly populates the aggregate on scope Creation" do
      actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")
      name = "Scope name"
      parent_scope_id = UUID.new("00000000-0000-0000-0000-200000000001")

      aggregate = Scopes::Aggregate.new(aggregate_id)

      # Creation request
      event_1 = Scopes::Creation::Events::Requested.new(
        actor_id: actor_id,
        command_handler: "test",
        name: name,
        parent_scope_id: parent_scope_id
      )
      aggregate.apply(event_1)

      # Accepted
      event_2 = Scopes::Creation::Events::Accepted.new(
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
      state.parent_scope_id.should eq(parent_scope_id)
    end
  end
end
