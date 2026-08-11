require "../../../../spec_helper"

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

private def assign_roles_command(aggregate_id : UUID, user_id : UUID, role_ids : Array(UUID), scope_id : UUID) : Users::AssignRoles::Commands::Request
  Users::AssignRoles::Commands::Request.new(aggregate_id: aggregate_id, user_id: user_id, role_ids: role_ids, actor_id: UUID.v7, scope_id: scope_id)
end

describe CrystalBank::Domains::Users::AssignRoles::Commands::RequestHandler do
  scope_id = UUID.new("00000000-0000-0000-0000-000000000001")

  it "raises when a role does not exist" do
    user_id = seed_user_for_assign(scope_id)

    expect_raises(ES::Exception::NotFound) do
      Users::AssignRoles::Commands::RequestHandler.new.handle(assign_roles_command(UUID.v7, user_id, [UUID.v7], scope_id))
    end
  end

  it "raises when a role is already assigned to the user" do
    role_id = seed_role_for_assign(scope_id)
    user_id = UUID.v7

    onboarded = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    onboarding_accepted = Test::User::Events::Onboarding::Accepted.new.create(aggr_id: user_id)
    already_assigned = Test::User::Events::AssignRoles::Accepted.new.create(aggr_id: user_id, role_ids: [role_id])
    TEST_EVENT_STORE.append(onboarded)
    TEST_EVENT_STORE.append(onboarding_accepted)
    TEST_EVENT_STORE.append(already_assigned)

    expect_raises(CrystalBank::Exception::InvalidArgument, /already assigned/) do
      Users::AssignRoles::Commands::RequestHandler.new.handle(assign_roles_command(UUID.v7, user_id, [role_id], scope_id))
    end
  end

  it "appends a Requested event under the given request aggregate ID" do
    role_id = seed_role_for_assign(scope_id)
    user_id = seed_user_for_assign(scope_id)
    request_id = UUID.v7

    Users::AssignRoles::Commands::RequestHandler.new.handle(assign_roles_command(request_id, user_id, [role_id], scope_id))

    request = Users::AssignRolesRequest::Aggregate.new(request_id)
    request.hydrate
    request.state.user_id.should eq(user_id)
    request.state.role_ids.should eq([role_id])
  end
end
