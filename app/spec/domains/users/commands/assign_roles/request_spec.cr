require "../../../../spec_helper"

private def make_assign_roles_context(scope_id : UUID) : CrystalBank::Api::Context
  CrystalBank::Api::Context.new(
    user_id: UUID.v7,
    roles: [] of UUID,
    required_permission: CrystalBank::Permissions::WRITE_users_assign_roles_request,
    scope: scope_id,
    available_scopes: [scope_id]
  )
end

private def seed_role_for_assign(scope_id : UUID) : UUID
  role_id = UUID.v7
  req = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
  acc = Test::Role::Events::Creation::Accepted.new.create(aggr_id: role_id)
  TEST_EVENT_STORE.append(req)
  TEST_EVENT_STORE.append(acc)
  Roles::Projections::Roles.new.apply(req)
  Roles::Projections::Roles.new.apply(acc)
  role_id
end

private def seed_user_for_assign(scope_id : UUID) : UUID
  user_id = UUID.v7
  req = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
  acc = Test::User::Events::Onboarding::Accepted.new.create(aggr_id: user_id)
  TEST_EVENT_STORE.append(req)
  TEST_EVENT_STORE.append(acc)
  user_id
end

describe CrystalBank::Domains::Users::AssignRoles::Commands::Request do
  scope_id = UUID.new("00000000-0000-0000-0000-000000000001")

  it "raises when scope is missing from context" do
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_users_assign_roles_request,
      scope: nil,
      available_scopes: [] of UUID
    )
    user_id = seed_user_for_assign(scope_id)
    r = Users::Api::Requests::AssignRolesRequest.from_json(%({"role_ids":[]}))

    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid scope/) do
      Users::AssignRoles::Commands::Request.new.call(user_id, r, context)
    end
  end

  it "raises when a role does not exist" do
    context = make_assign_roles_context(scope_id)
    user_id = seed_user_for_assign(scope_id)
    r = Users::Api::Requests::AssignRolesRequest.from_json(%({"role_ids":["#{UUID.v7}"]}))

    expect_raises(ES::Exception::NotFound) do
      Users::AssignRoles::Commands::Request.new.call(user_id, r, context)
    end
  end

  it "raises when a role is already assigned to the user" do
    context = make_assign_roles_context(scope_id)
    role_id = seed_role_for_assign(scope_id)
    user_id = UUID.v7

    onboarded = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    already_assigned = Test::User::Events::AssignRoles::Accepted.new.create(aggr_id: user_id, role_ids: [role_id])
    TEST_EVENT_STORE.append(onboarded)
    TEST_EVENT_STORE.append(already_assigned)

    r = Users::Api::Requests::AssignRolesRequest.from_json(%({"role_ids":["#{role_id}"]}))

    expect_raises(CrystalBank::Exception::InvalidArgument, /already assigned/) do
      Users::AssignRoles::Commands::Request.new.call(user_id, r, context)
    end
  end

  it "returns a request aggregate UUID when the request is valid" do
    context = make_assign_roles_context(scope_id)
    role_id = seed_role_for_assign(scope_id)
    user_id = seed_user_for_assign(scope_id)

    r = Users::Api::Requests::AssignRolesRequest.from_json(%({"role_ids":["#{role_id}"]}))

    request_id = Users::AssignRoles::Commands::Request.new.call(user_id, r, context)

    request_id.should be_a(UUID)
    request_id.should_not eq(user_id)
  end
end
