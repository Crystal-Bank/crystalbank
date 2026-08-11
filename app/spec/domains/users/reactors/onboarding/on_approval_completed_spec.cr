require "../../../../spec_helper"

describe CrystalBank::Domains::Users::Reactors::Onboarding::OnApprovalCompleted do
  it "marks the user as onboarded after the approval is completed" do
    user_id = UUID.v7

    requested = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    TEST_EVENT_STORE.append(requested)

    approval_id = UUID.v7
    Approvals::Creation::Commands::RequestHandler.new.handle(
      Approvals::Creation::Commands::Request.new(
        aggregate_id: approval_id,
        source_aggregate_type: "User",
        source_aggregate_id: user_id,
        scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
        required_approvals: ["write_users_onboarding_compliance_approval"],
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

    Users::Reactors::Onboarding::OnApprovalCompleted.new.call(completed_event)

    aggregate = Users::Aggregate.new(user_id)
    aggregate.hydrate

    aggregate.state.onboarded.should be_true
  end

  it "ignores a completed approval with a different source aggregate type" do
    approval_id = UUID.v7
    Approvals::Creation::Commands::RequestHandler.new.handle(
      Approvals::Creation::Commands::Request.new(
        aggregate_id: approval_id,
        source_aggregate_type: "SomeUnhandledType",
        source_aggregate_id: UUID.v7,
        scope_id: UUID.v7,
        required_approvals: ["write_users_onboarding_compliance_approval"],
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

    # Should not raise — OnApprovalCompleted silently returns when source type != "User"
    Users::Reactors::Onboarding::OnApprovalCompleted.new.call(completed_event)
  end
end
