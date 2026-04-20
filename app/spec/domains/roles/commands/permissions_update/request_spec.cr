require "../../../../spec_helper"

private def permissions_update_context(scope : UUID? = UUID.new("00000000-0000-0000-0000-100000000001"))
  CrystalBank::Api::Context.new(
    user_id: UUID.v7,
    roles: [] of UUID,
    required_permission: CrystalBank::Permissions::WRITE_roles_permissions_update_request,
    scope: scope,
    available_scopes: scope ? [scope] : [] of UUID
  )
end

private def permissions_update_request(role_id : UUID, permissions : Array(String) = ["write_roles_permissions_update_request"])
  Roles::Api::Requests::PermissionsUpdateRequest.from_json({
    role_id:     role_id.to_s,
    permissions: permissions,
  }.to_json)
end

private def seed_active_role(role_id : UUID)
  req = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
  acc = Test::Role::Events::Creation::Accepted.new.create(aggr_id: role_id)
  TEST_EVENT_STORE.append(req)
  TEST_EVENT_STORE.append(acc)
  Roles::Projections::Roles.new.apply(req)
  Roles::Projections::Roles.new.apply(acc)
end

describe CrystalBank::Domains::Roles::PermissionsUpdate::Commands::Request do
  it "returns a permissions update request UUID and creates an approval" do
    role_id = UUID.v7
    seed_active_role(role_id)

    update_request_id = Roles::PermissionsUpdate::Commands::Request.new.call(
      permissions_update_request(role_id: role_id),
      permissions_update_context
    )

    update_request_id.should be_a(UUID)

    aggregate = Roles::PermissionsUpdate::Aggregate.new(update_request_id)
    aggregate.hydrate

    aggregate.state.role_id.should eq(role_id)
    aggregate.state.permissions.should eq([CrystalBank::Permissions::WRITE_roles_permissions_update_request])
    aggregate.state.completed.should be_false
  end

  it "raises when the role does not exist" do
    expect_raises(CrystalBank::Exception::InvalidArgument, /not found/) do
      Roles::PermissionsUpdate::Commands::Request.new.call(
        permissions_update_request(role_id: UUID.v7),
        permissions_update_context
      )
    end
  end

  it "raises when the role is not active (pending_approval)" do
    role_id = UUID.v7
    req = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
    TEST_EVENT_STORE.append(req)
    Roles::Projections::Roles.new.apply(req)

    expect_raises(CrystalBank::Exception::InvalidArgument, /not active/) do
      Roles::PermissionsUpdate::Commands::Request.new.call(
        permissions_update_request(role_id: role_id),
        permissions_update_context
      )
    end
  end

  it "raises when submitted permissions are identical to the current permissions" do
    role_id = UUID.v7
    seed_active_role(role_id)

    # The factory seeds the role with WRITE_roles_creation_request
    expect_raises(CrystalBank::Exception::InvalidArgument, /unchanged/) do
      Roles::PermissionsUpdate::Commands::Request.new.call(
        permissions_update_request(role_id: role_id, permissions: ["write_roles_creation_request"]),
        permissions_update_context
      )
    end
  end

  it "raises when the role already has a pending permissions update" do
    role_id = UUID.v7
    seed_active_role(role_id)

    # First request succeeds
    update_request_id = Roles::PermissionsUpdate::Commands::Request.new.call(
      permissions_update_request(role_id: role_id),
      permissions_update_context
    )

    # Project the Requested event so the pending guard has data
    apply_projection(update_request_id)

    # Second request for the same role must be rejected
    expect_raises(CrystalBank::Exception::InvalidArgument, /already has a pending permissions update/) do
      Roles::PermissionsUpdate::Commands::Request.new.call(
        permissions_update_request(role_id: role_id, permissions: ["write_roles_permissions_update_approval"]),
        permissions_update_context
      )
    end
  end

  it "raises when scope is missing from context" do
    role_id = UUID.v7
    seed_active_role(role_id)

    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid scope/) do
      Roles::PermissionsUpdate::Commands::Request.new.call(
        permissions_update_request(role_id: role_id),
        permissions_update_context(scope: nil)
      )
    end
  end
end
