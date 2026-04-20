require "../../../spec_helper"

describe CrystalBank::Domains::Roles::PermissionsUpdate::Aggregate do
  describe "RolePermissionsUpdate aggregate state" do
    it "populates state after Requested event" do
      update_request_id = UUID.new("00000000-0000-0000-0000-000000000003")
      role_id = UUID.new("00000000-0000-0000-0000-000000000001")
      requestor_id = UUID.new("00000000-0000-0000-0000-000000000000")

      aggregate = Roles::PermissionsUpdate::Aggregate.new(update_request_id)

      event = Roles::PermissionsUpdate::Events::Requested.new(
        actor_id: requestor_id,
        command_handler: "test",
        role_id: role_id,
        permissions: [CrystalBank::Permissions::WRITE_roles_permissions_update_request]
      )
      aggregate.apply(event)

      state = aggregate.state
      state.role_id.should eq(role_id)
      state.permissions.should eq([CrystalBank::Permissions::WRITE_roles_permissions_update_request])
      state.requestor_id.should eq(requestor_id)
      state.completed.should be_false
    end

    it "marks aggregate completed after Completed event" do
      update_request_id = UUID.new("00000000-0000-0000-0000-000000000003")

      aggregate = Roles::PermissionsUpdate::Aggregate.new(update_request_id)

      event_1 = Roles::PermissionsUpdate::Events::Requested.new(
        actor_id: UUID.new("00000000-0000-0000-0000-000000000000"),
        command_handler: "test",
        role_id: UUID.new("00000000-0000-0000-0000-000000000001"),
        permissions: [CrystalBank::Permissions::WRITE_roles_permissions_update_request]
      )
      aggregate.apply(event_1)

      event_2 = Roles::PermissionsUpdate::Events::Completed.new(
        actor_id: nil,
        aggregate_id: update_request_id,
        aggregate_version: aggregate.state.aggregate_version + 1,
        command_handler: "test"
      )
      aggregate.apply(event_2)

      aggregate.state.completed.should be_true
      aggregate.state.aggregate_version.should eq(2)
    end
  end

  describe "Role aggregate — permissions update concern" do
    it "updates permissions after PermissionsUpdate::Accepted event" do
      role_id = UUID.new("00000000-0000-0000-0000-000000000001")
      actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
      original_permissions = [CrystalBank::Permissions::WRITE_roles_creation_request]
      new_permissions = [CrystalBank::Permissions::WRITE_roles_permissions_update_request]

      role = Roles::Aggregate.new(role_id)

      # Bring the role to active state via creation events
      creation_requested = Roles::Creation::Events::Requested.new(
        actor_id: actor_id,
        command_handler: "test",
        name: "Test Role",
        permissions: original_permissions,
        scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
        scopes: [UUID.new("00000000-0000-0000-0000-200000000001")]
      )
      role.apply(creation_requested)

      creation_accepted = Roles::Creation::Events::Accepted.new(
        actor_id: nil,
        aggregate_id: role_id,
        aggregate_version: role.state.aggregate_version + 1,
        command_handler: "test"
      )
      role.apply(creation_accepted)

      role.state.permissions.should eq(original_permissions)
      role.state.aggregate_version.should eq(2)

      # Apply permissions update
      perm_accepted = Roles::PermissionsUpdate::Events::Accepted.new(
        actor_id: actor_id,
        aggregate_id: role_id,
        aggregate_version: role.state.aggregate_version + 1,
        command_handler: "test",
        permissions: new_permissions
      )
      role.apply(perm_accepted)

      role.state.permissions.should eq(new_permissions)
      role.state.aggregate_version.should eq(3)
    end
  end
end
