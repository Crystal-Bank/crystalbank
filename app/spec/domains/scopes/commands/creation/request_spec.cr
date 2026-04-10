require "../../../../spec_helper"

describe CrystalBank::Domains::Scopes::Creation::Commands::Request do
  it "defaults parent_scope_id to x-scope when not provided" do
    scope_id = UUID.v7
    scope_requested = Test::Scope::Events::Creation::Requested.new.create(aggr_id: scope_id)
    scope_accepted = Test::Scope::Events::Creation::Accepted.new.create(aggr_id: scope_id)
    TEST_EVENT_STORE.append(scope_requested)
    TEST_EVENT_STORE.append(scope_accepted)

    user_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id: user_id,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_scopes_creation_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    request = Scopes::Api::Requests::CreationRequest.from_json(%({"name": "Child Scope"}))
    result = Scopes::Creation::Commands::Request.new.call(request, context)

    result.should be_a(UUID)

    aggregate = Scopes::Aggregate.new(result)
    aggregate.hydrate

    aggregate.state.name.should eq("Child Scope")
    aggregate.state.parent_scope_id.should eq(scope_id)
    aggregate.state.scope_id.should eq(scope_id)
  end

  it "creates a scope with an active parent scope" do
    parent_scope_id = UUID.v7
    parent_requested = Test::Scope::Events::Creation::Requested.new.create(aggr_id: parent_scope_id)
    parent_accepted = Test::Scope::Events::Creation::Accepted.new.create(aggr_id: parent_scope_id)
    TEST_EVENT_STORE.append(parent_requested)
    TEST_EVENT_STORE.append(parent_accepted)

    scope_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_scopes_creation_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    request = Scopes::Api::Requests::CreationRequest.from_json(%({"name": "Child Scope", "parent_scope_id": "#{parent_scope_id}"}))
    result = Scopes::Creation::Commands::Request.new.call(request, context)

    result.should be_a(UUID)

    aggregate = Scopes::Aggregate.new(result)
    aggregate.hydrate

    aggregate.state.name.should eq("Child Scope")
    aggregate.state.parent_scope_id.should eq(parent_scope_id)
  end

  it "raises when parent scope is not yet active (only requested, not accepted)" do
    parent_scope_id = UUID.v7
    parent_requested = Test::Scope::Events::Creation::Requested.new.create(aggr_id: parent_scope_id)
    TEST_EVENT_STORE.append(parent_requested)

    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_scopes_creation_request,
      scope: UUID.v7,
      available_scopes: [UUID.v7]
    )

    request = Scopes::Api::Requests::CreationRequest.from_json(%({"name": "Child Scope", "parent_scope_id": "#{parent_scope_id}"}))

    expect_raises(CrystalBank::Exception::InvalidArgument, /Parent scope is not active/) do
      Scopes::Creation::Commands::Request.new.call(request, context)
    end
  end

  it "raises when parent scope does not exist" do
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_scopes_creation_request,
      scope: UUID.v7,
      available_scopes: [UUID.v7]
    )

    request = Scopes::Api::Requests::CreationRequest.from_json(%({"name": "Child Scope", "parent_scope_id": "#{UUID.v7}"}))

    expect_raises(CrystalBank::Exception::InvalidArgument, /Parent scope is not active/) do
      Scopes::Creation::Commands::Request.new.call(request, context)
    end
  end

  it "raises when scope is missing from context" do
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_scopes_creation_request,
      scope: nil,
      available_scopes: [] of UUID
    )

    request = Scopes::Api::Requests::CreationRequest.from_json(%({"name": "Test Scope"}))

    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid scope/) do
      Scopes::Creation::Commands::Request.new.call(request, context)
    end
  end
end
