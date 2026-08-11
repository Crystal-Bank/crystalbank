require "../../../../spec_helper"

describe CrystalBank::Domains::Roles::Reactors::Creation::OnApprovalCompleted do
  it "accepts the role after the approval is completed" do
    role_id = UUID.v7

    requested = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
    TEST_EVENT_STORE.append(requested)

    approval_id = UUID.v7
    Approvals::Creation::Commands::RequestHandler.new.handle(
      Approvals::Creation::Commands::Request.new(
        aggregate_id: approval_id,
        source_aggregate_type: "Role",
        source_aggregate_id: role_id,
        scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
        required_approvals: ["write_roles_creation_approval"],
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

    Roles::Reactors::Creation::OnApprovalCompleted.new.call(completed_event)

    aggregate = Roles::Aggregate.new(role_id)
    aggregate.hydrate

    aggregate.state.aggregate_version.should eq(2)
  end

  it "ignores a completed approval with a different source aggregate type" do
    approval_id = UUID.v7
    Approvals::Creation::Commands::RequestHandler.new.handle(
      Approvals::Creation::Commands::Request.new(
        aggregate_id: approval_id,
        source_aggregate_type: "SomeUnhandledType",
        source_aggregate_id: UUID.v7,
        scope_id: UUID.v7,
        required_approvals: ["write_roles_creation_approval"],
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

    # Should not raise — OnApprovalCompleted silently returns when source type != "Role"
    Roles::Reactors::Creation::OnApprovalCompleted.new.call(completed_event)
  end
end
