require "../../../../spec_helper"

describe CrystalBank::Domains::Scopes::Creation::Commands::RequestHandler do
  it "defaults parent_scope_id to x-scope when not provided" do
    scope_id = UUID.v7
    scope_requested = Test::Scope::Events::Creation::Requested.new.create(aggr_id: scope_id)
    scope_accepted = Test::Scope::Events::Creation::Accepted.new.create(aggr_id: scope_id)
    TEST_EVENT_STORE.append(scope_requested)
    TEST_EVENT_STORE.append(scope_accepted)

    aggregate_id = UUID.v7
    request = Scopes::Api::Requests::CreationRequest.from_json(%({"name": "Child Scope"}))
    Scopes::Creation::Commands::RequestHandler.new.handle(
      Scopes::Creation::Commands::Request.new(
        aggregate_id: aggregate_id, name: request.name, parent_scope_id: request.parent_scope_id, scope_id: scope_id, actor_id: UUID.v7
      )
    )

    aggregate = Scopes::Aggregate.new(aggregate_id)
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
    aggregate_id = UUID.v7
    request = Scopes::Api::Requests::CreationRequest.from_json(%({"name": "Child Scope", "parent_scope_id": "#{parent_scope_id}"}))
    Scopes::Creation::Commands::RequestHandler.new.handle(
      Scopes::Creation::Commands::Request.new(
        aggregate_id: aggregate_id, name: request.name, parent_scope_id: request.parent_scope_id, scope_id: scope_id, actor_id: UUID.v7
      )
    )

    aggregate = Scopes::Aggregate.new(aggregate_id)
    aggregate.hydrate

    aggregate.state.name.should eq("Child Scope")
    aggregate.state.parent_scope_id.should eq(parent_scope_id)
  end

  it "raises when parent scope is not yet active (only requested, not accepted)" do
    parent_scope_id = UUID.v7
    parent_requested = Test::Scope::Events::Creation::Requested.new.create(aggr_id: parent_scope_id)
    TEST_EVENT_STORE.append(parent_requested)

    request = Scopes::Api::Requests::CreationRequest.from_json(%({"name": "Child Scope", "parent_scope_id": "#{parent_scope_id}"}))

    expect_raises(CrystalBank::Exception::InvalidArgument, /Parent scope is not active/) do
      Scopes::Creation::Commands::RequestHandler.new.handle(
        Scopes::Creation::Commands::Request.new(
          aggregate_id: UUID.v7, name: request.name, parent_scope_id: request.parent_scope_id, scope_id: UUID.v7, actor_id: UUID.v7
        )
      )
    end
  end

  it "raises when parent scope does not exist" do
    request = Scopes::Api::Requests::CreationRequest.from_json(%({"name": "Child Scope", "parent_scope_id": "#{UUID.v7}"}))

    expect_raises(CrystalBank::Exception::InvalidArgument, /Parent scope is not active/) do
      Scopes::Creation::Commands::RequestHandler.new.handle(
        Scopes::Creation::Commands::Request.new(
          aggregate_id: UUID.v7, name: request.name, parent_scope_id: request.parent_scope_id, scope_id: UUID.v7, actor_id: UUID.v7
        )
      )
    end
  end
end
