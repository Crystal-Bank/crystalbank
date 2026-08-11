require "../../../../spec_helper"

describe CrystalBank::Domains::Scopes::Reactors::NameChange::OnApprovalCompleted do
  it "applies the new name to the scope and marks the request as completed after approval" do
    scope_id = UUID.v7

    scope_req = Test::Scope::Events::Creation::Requested.new.create(aggr_id: scope_id)
    scope_acc = Test::Scope::Events::Creation::Accepted.new.create(aggr_id: scope_id)
    TEST_EVENT_STORE.append(scope_req)
    TEST_EVENT_STORE.append(scope_acc)
    Scopes::Projections::Scopes.new.apply(scope_req)
    Scopes::Projections::Scopes.new.apply(scope_acc)

    result = Scopes::NameChange::Commands::RequestHandler.new.handle(
      Scopes::NameChange::Commands::Request.new(
        aggregate_id: UUID.v7, target_scope_id: scope_id, name: "Renamed Scope", actor_id: UUID.v7, scope_id: scope_id
      )
    )
    name_change_request_id = result[:name_change_request_id]
    approval_id = result[:approval_id]

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    Scopes::Reactors::NameChange::OnApprovalCompleted.new.call(completed_event)

    scope = Scopes::Aggregate.new(scope_id)
    scope.hydrate
    scope.state.name.should eq("Renamed Scope")

    name_change_request = Scopes::NameChange::Aggregate.new(name_change_request_id)
    name_change_request.hydrate
    name_change_request.state.completed.should be_true
  end

  it "does not process the same approval twice" do
    scope_id = UUID.v7

    scope_req = Test::Scope::Events::Creation::Requested.new.create(aggr_id: scope_id)
    scope_acc = Test::Scope::Events::Creation::Accepted.new.create(aggr_id: scope_id)
    TEST_EVENT_STORE.append(scope_req)
    TEST_EVENT_STORE.append(scope_acc)
    Scopes::Projections::Scopes.new.apply(scope_req)
    Scopes::Projections::Scopes.new.apply(scope_acc)

    result = Scopes::NameChange::Commands::RequestHandler.new.handle(
      Scopes::NameChange::Commands::Request.new(
        aggregate_id: UUID.v7, target_scope_id: scope_id, name: "Renamed Scope", actor_id: UUID.v7, scope_id: scope_id
      )
    )
    approval_id = result[:approval_id]

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    Scopes::Reactors::NameChange::OnApprovalCompleted.new.call(completed_event)

    # Simulate queue redelivery by calling the reactor a second time directly.
    # The completed guard must prevent a second Accepted event from being appended.
    Scopes::Reactors::NameChange::OnApprovalCompleted.new.call(completed_event)

    scope = Scopes::Aggregate.new(scope_id)
    scope.hydrate
    scope.state.name.should eq("Renamed Scope")
    scope.state.aggregate_version.should eq(3)
  end

  it "ignores a completed approval with a different source aggregate type" do
    approval_id = UUID.v7
    Approvals::Creation::Commands::RequestHandler.new.handle(
      Approvals::Creation::Commands::Request.new(
        aggregate_id: approval_id,
        source_aggregate_type: "SomeUnhandledType",
        source_aggregate_id: UUID.v7,
        scope_id: UUID.v7,
        required_approvals: ["write_scopes_name_change_approval"],
        actor_id: UUID.v7,
      )
    )

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    Scopes::Reactors::NameChange::OnApprovalCompleted.new.call(completed_event)
  end
end
