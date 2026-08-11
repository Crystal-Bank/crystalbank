require "../../../../spec_helper"

private def permissions_update_command(aggregate_id : UUID, role_id : UUID, permissions : Array(CrystalBank::Permissions) = [CrystalBank::Permissions::WRITE_roles_permissions_update_request]) : Roles::PermissionsUpdate::Commands::Request
  Roles::PermissionsUpdate::Commands::Request.new(
    aggregate_id: aggregate_id, role_id: role_id, permissions: permissions,
    actor_id: UUID.v7, scope_id: UUID.new("00000000-0000-0000-0000-100000000001")
  )
end

private def seed_active_role(role_id : UUID)
  req = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
  acc = Test::Role::Events::Creation::Accepted.new.create(aggr_id: role_id)
  TEST_EVENT_STORE.append(req)
  TEST_EVENT_STORE.append(acc)
  Roles::Projections::Roles.new.apply(req)
  Roles::Projections::Roles.new.apply(acc)
  # The audit projection's scope_id_for self-lookup (used by the
  # RolePermissionsUpdate::Requested apply overload) needs the role's own
  # audit trail populated, exactly as the real event bus would do.
  Events::Projections::Events.new.apply(req)
  Events::Projections::Events.new.apply(acc)
end

describe CrystalBank::Domains::Roles::PermissionsUpdate::Commands::RequestHandler do
  it "creates a permissions update request and an approval under the given aggregate ID" do
    role_id = UUID.v7
    seed_active_role(role_id)
    update_request_id = UUID.v7

    result = Roles::PermissionsUpdate::Commands::RequestHandler.new.handle(permissions_update_command(update_request_id, role_id))

    result[:update_request_id].should eq(update_request_id)
    result[:approval_id].should be_a(UUID)

    aggregate = Roles::PermissionsUpdate::Aggregate.new(update_request_id)
    aggregate.hydrate

    aggregate.state.role_id.should eq(role_id)
    aggregate.state.permissions.should eq([CrystalBank::Permissions::WRITE_roles_permissions_update_request])
    aggregate.state.completed.should be_false
  end

  it "creates an approval with a subject snapshot containing role name and permission count" do
    role_id = UUID.v7
    seed_active_role(role_id)
    update_request_id = UUID.v7

    result = Roles::PermissionsUpdate::Commands::RequestHandler.new.handle(permissions_update_command(update_request_id, role_id))

    apply_projection(result[:approval_id])

    approval = Approvals::Queries::Approvals.new.find_by_source("RolePermissionsUpdate", update_request_id)
    approval.should_not be_nil

    subject = approval.not_nil!.subject
    subject.should_not be_nil
    subject.not_nil!.title.should eq("Role Permissions Update")
    subject.not_nil!.summary.should contain("Scope name test")
    subject.not_nil!.summary.should contain("1 permissions")
    field_labels = subject.not_nil!.fields.map(&.label)
    field_labels.should contain("Role")
    field_labels.should contain("Permissions")
    subject.not_nil!.fields.find { |f| f.label == "Role" }.not_nil!.value.should eq("Scope name test")
    subject.not_nil!.fields.find { |f| f.label == "Permissions" }.not_nil!.value.should eq("1")
  end

  it "raises when the role does not exist" do
    expect_raises(CrystalBank::Exception::InvalidArgument, /not found/) do
      Roles::PermissionsUpdate::Commands::RequestHandler.new.handle(permissions_update_command(UUID.v7, UUID.v7))
    end
  end

  it "raises when the role is not active (pending_approval)" do
    role_id = UUID.v7
    req = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
    TEST_EVENT_STORE.append(req)
    Roles::Projections::Roles.new.apply(req)

    expect_raises(CrystalBank::Exception::InvalidArgument, /not active/) do
      Roles::PermissionsUpdate::Commands::RequestHandler.new.handle(permissions_update_command(UUID.v7, role_id))
    end
  end

  it "raises when submitted permissions are identical to the current permissions" do
    role_id = UUID.v7
    seed_active_role(role_id)

    # The factory seeds the role with WRITE_roles_creation_request
    expect_raises(CrystalBank::Exception::InvalidArgument, /unchanged/) do
      Roles::PermissionsUpdate::Commands::RequestHandler.new.handle(
        permissions_update_command(UUID.v7, role_id, [CrystalBank::Permissions::WRITE_roles_creation_request])
      )
    end
  end

  it "raises when the role already has a pending permissions update" do
    role_id = UUID.v7
    seed_active_role(role_id)

    # First request succeeds
    result = Roles::PermissionsUpdate::Commands::RequestHandler.new.handle(permissions_update_command(UUID.v7, role_id))

    # Project the Requested event so the pending guard has data
    apply_projection(result[:update_request_id])

    # Second request for the same role must be rejected
    expect_raises(CrystalBank::Exception::InvalidArgument, /already has a pending permissions update/) do
      Roles::PermissionsUpdate::Commands::RequestHandler.new.handle(
        permissions_update_command(UUID.v7, role_id, [CrystalBank::Permissions::WRITE_roles_permissions_update_approval])
      )
    end
  end
end
