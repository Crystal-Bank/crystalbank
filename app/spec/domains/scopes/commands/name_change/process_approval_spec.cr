require "../../../../spec_helper"

describe CrystalBank::Domains::Scopes::NameChange::Commands::ProcessApproval do
  it "applies the new name to the scope and marks the request as completed after approval" do
    scope_id = UUID.v7

    scope_req = Test::Scope::Events::Creation::Requested.new.create(aggr_id: scope_id)
    scope_acc = Test::Scope::Events::Creation::Accepted.new.create(aggr_id: scope_id)
    TEST_EVENT_STORE.append(scope_req)
    TEST_EVENT_STORE.append(scope_acc)

    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_scopes_name_change_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )
    Scopes::Projections::Scopes.new.apply(scope_req)
    Scopes::Projections::Scopes.new.apply(scope_acc)

    request = Scopes::Api::Requests::NameChangeRequest.from_json(
      {scope_id: scope_id.to_s, name: "Renamed Scope"}.to_json
    )
    result = Scopes::NameChange::Commands::Request.new.call(request, context)
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

    apply_projection(approval_id)

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

    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_scopes_name_change_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )
    Scopes::Projections::Scopes.new.apply(scope_req)
    Scopes::Projections::Scopes.new.apply(scope_acc)

    request = Scopes::Api::Requests::NameChangeRequest.from_json(
      {scope_id: scope_id.to_s, name: "Renamed Scope"}.to_json
    )
    result = Scopes::NameChange::Commands::Request.new.call(request, context)
    approval_id = result[:approval_id]

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    apply_projection(approval_id)

    # Simulate queue redelivery by calling ProcessApproval a second time directly.
    # The completed guard must prevent a second Accepted event from being appended.
    Scopes::NameChange::Commands::ProcessApproval.new(aggregate_id: approval_id).call

    scope = Scopes::Aggregate.new(scope_id)
    scope.hydrate
    scope.state.name.should eq("Renamed Scope")
    scope.state.aggregate_version.should eq(3)
  end

  it "ignores a completed approval with a different source aggregate type" do
    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "SomeUnhandledType",
      source_aggregate_id: UUID.v7,
      scope_id: UUID.v7,
      required_approvals: ["write_scopes_name_change_approval"],
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
  end
end
