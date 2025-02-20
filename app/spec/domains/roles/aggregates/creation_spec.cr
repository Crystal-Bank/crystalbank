require "../../../spec_helper"

describe CrystalBank::Domains::Roles::Aggregates::Concerns::Creation do
  describe "#apply" do
    it "Properly populates the aggregate on role creation" do
      actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")
      name = "Scope name"
      permissions = [CrystalBank::Permissions::WRITE_roles_creation]
      scopes = [UUID.new("00000000-0000-0000-0000-200000000001")]

      aggregate = Roles::Aggregate.new(aggregate_id)

      # Creation request
      event_1 = Roles::Creation::Events::Requested.new(
        actor_id: actor_id,
        command_handler: "test",
        name: name,
        permissions: permissions,
        scopes: scopes
      )
      aggregate.apply(event_1)

      # Accepted
      event_2 = Roles::Creation::Events::Accepted.new(
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
      state.permissions.should eq(permissions)
      state.scopes.should eq(scopes)
    end
  end
end
