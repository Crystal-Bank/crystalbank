require "../../../../spec_helper"

describe CrystalBank::Domains::Roles::PermissionsUpdate::Commands::ProcessApproval do
  it "applies new permissions to the role and marks the update request completed" do
    role_id = UUID.v7
    update_request_id = UUID.v7

    # Bring the Role aggregate to active state (v1 Requested + v2 Accepted)
    TEST_EVENT_STORE.append(Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id))
    TEST_EVENT_STORE.append(Test::Role::Events::Creation::Accepted.new.create(aggr_id: role_id))

    # Append the permissions update request on its own aggregate
    perm_requested = Test::Role::Events::PermissionsUpdate::Requested.new.create(
      aggr_id: update_request_id,
      role_id: role_id
    )
    TEST_EVENT_STORE.append(perm_requested)

    # Create the approval workflow for this update request
    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "RolePermissionsUpdate",
      source_aggregate_id: update_request_id,
      scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
      required_approvals: ["write_roles_permissions_update_approval"],
      actor_id: UUID.v7,
    )

    # Complete the approval
    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    # Replay approval events through the bus — triggers ProcessApproval
    apply_projection(approval_id)

    # Role aggregate should have new permissions at version 3
    role = Roles::Aggregate.new(role_id)
    role.hydrate
    role.state.aggregate_version.should eq(3)
    role.state.permissions.should eq([CrystalBank::Permissions::WRITE_roles_permissions_update_request])

    # RolePermissionsUpdate aggregate should be marked completed
    update_request = Roles::PermissionsUpdate::Aggregate.new(update_request_id)
    update_request.hydrate
    update_request.state.completed.should be_true
  end

  it "ignores a completed approval for a different source aggregate type" do
    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "SomeOtherType",
      source_aggregate_id: UUID.v7,
      scope_id: UUID.v7,
      required_approvals: ["write_roles_permissions_update_approval"],
      actor_id: UUID.v7,
    )

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    # Should not raise — ProcessApproval silently returns for non-RolePermissionsUpdate types
    apply_projection(approval_id)
  end

  it "is idempotent when the approval fires more than once" do
    role_id = UUID.v7
    update_request_id = UUID.v7

    TEST_EVENT_STORE.append(Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id))
    TEST_EVENT_STORE.append(Test::Role::Events::Creation::Accepted.new.create(aggr_id: role_id))

    perm_requested = Test::Role::Events::PermissionsUpdate::Requested.new.create(
      aggr_id: update_request_id,
      role_id: role_id
    )
    TEST_EVENT_STORE.append(perm_requested)

    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "RolePermissionsUpdate",
      source_aggregate_id: update_request_id,
      scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
      required_approvals: ["write_roles_permissions_update_approval"],
      actor_id: UUID.v7,
    )

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    apply_projection(approval_id)
    # Second replay — guard `completed == true` prevents double application
    apply_projection(approval_id)

    role = Roles::Aggregate.new(role_id)
    role.hydrate
    role.state.aggregate_version.should eq(3)
  end
end
