require "../../../../spec_helper"

describe CrystalBank::Domains::Scopes::Creation::Commands::ProcessApproval do
  it "marks the scope as accepted after the approval is completed" do
    scope_id = UUID.v7

    requested = Test::Scope::Events::Creation::Requested.new.create(aggr_id: scope_id)
    TEST_EVENT_STORE.append(requested)

    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "Scope",
      source_aggregate_id: scope_id,
      scope_id: UUID.new("00000000-0000-0000-0000-000000000001"),
      required_approvals: ["write_scopes_creation_approval"],
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

    scope = Scopes::Aggregate.new(scope_id)
    scope.hydrate

    scope.state.accepted.should be_true
  end

  it "ignores a completed approval with a different source aggregate type" do
    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "SomeUnhandledType",
      source_aggregate_id: UUID.v7,
      scope_id: UUID.v7,
      required_approvals: ["write_scopes_creation_approval"],
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
