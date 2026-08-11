require "../../../../spec_helper"

private def role_creation_context(scope : UUID = UUID.new("00000000-0000-0000-0000-100000000001"))
  CrystalBank::Api::Context.new(
    user_id: UUID.v7,
    roles: [] of UUID,
    required_permission: CrystalBank::Permissions::WRITE_roles_creation_request,
    scope: scope,
    available_scopes: [scope]
  )
end

private def role_creation_request(scopes : Array(UUID) = [] of UUID)
  Roles::Api::Requests::CreationRequest.from_json({
    name:        "Test Role",
    permissions: ["write_roles_creation_request"],
    scopes:      scopes.map(&.to_s),
  }.to_json)
end

private def role_creation_command(aggregate_id : UUID, r : Roles::Api::Requests::CreationRequest, context : CrystalBank::Api::Context) : Roles::Creation::Commands::Request
  Roles::Creation::Commands::Request.new(
    aggregate_id: aggregate_id, name: r.name, permissions: r.permissions, scopes: r.scopes,
    scope_id: context.scope.not_nil!, actor_id: context.user_id, context: context
  )
end

describe CrystalBank::Domains::Roles::Creation::Commands::RequestHandler do
  it "appends a Requested event under the given aggregate ID" do
    active_scope_id = UUID.v7
    scope_event = Test::Scope::Events::Creation::Requested.new.create(aggr_id: active_scope_id)
    accepted_event = Test::Scope::Events::Creation::Accepted.new.create(aggr_id: active_scope_id)
    TEST_EVENT_STORE.append(scope_event)
    TEST_EVENT_STORE.append(accepted_event)
    Scopes::Projections::Scopes.new.apply(scope_event)
    Scopes::Projections::Scopes.new.apply(accepted_event)

    role_id = UUID.v7
    context = role_creation_context
    Roles::Creation::Commands::RequestHandler.new.handle(role_creation_command(role_id, role_creation_request(scopes: [active_scope_id]), context))

    aggregate = Roles::Aggregate.new(role_id)
    aggregate.hydrate

    aggregate.state.name.should eq("Test Role")
    aggregate.state.scope_id.should eq(UUID.new("00000000-0000-0000-0000-100000000001"))
    aggregate.state.aggregate_version.should eq(1)
  end

  it "raises when no scopes are provided" do
    context = role_creation_context
    expect_raises(CrystalBank::Exception::InvalidArgument, /Role needs to be applicable to at least one scope/) do
      Roles::Creation::Commands::RequestHandler.new.handle(role_creation_command(UUID.v7, role_creation_request, context))
    end
  end

  it "accepts valid active scope IDs" do
    active_scope_id = UUID.v7
    scope_event = Test::Scope::Events::Creation::Requested.new.create(aggr_id: active_scope_id)
    accepted_event = Test::Scope::Events::Creation::Accepted.new.create(aggr_id: active_scope_id)
    TEST_EVENT_STORE.append(scope_event)
    TEST_EVENT_STORE.append(accepted_event)
    Scopes::Projections::Scopes.new.apply(scope_event)
    Scopes::Projections::Scopes.new.apply(accepted_event)

    context = role_creation_context
    Roles::Creation::Commands::RequestHandler.new.handle(role_creation_command(UUID.v7, role_creation_request(scopes: [active_scope_id]), context))
  end

  it "raises when a provided scope ID does not exist" do
    nonexistent_id = UUID.v7
    context = role_creation_context

    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid or inactive scopes/) do
      Roles::Creation::Commands::RequestHandler.new.handle(role_creation_command(UUID.v7, role_creation_request(scopes: [nonexistent_id]), context))
    end
  end

  it "raises when a provided scope ID exists but is pending (not yet accepted)" do
    pending_scope_id = UUID.v7
    scope_event = Test::Scope::Events::Creation::Requested.new.create(aggr_id: pending_scope_id)
    TEST_EVENT_STORE.append(scope_event)
    Scopes::Projections::Scopes.new.apply(scope_event)

    context = role_creation_context
    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid or inactive scopes/) do
      Roles::Creation::Commands::RequestHandler.new.handle(role_creation_command(UUID.v7, role_creation_request(scopes: [pending_scope_id]), context))
    end
  end
end
