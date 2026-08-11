require "../../../../spec_helper"

describe CrystalBank::Domains::Customers::Reactors::Onboarding::OnApprovalCompleted do
  it "marks the customer as onboarded after the approval is completed" do
    customer_id = UUID.v7

    requested = Test::Customer::Events::Onboarding::Requested.new.create(aggr_id: customer_id)
    TEST_EVENT_STORE.append(requested)

    approval_id = UUID.v7
    Approvals::Creation::Commands::RequestHandler.new.handle(
      Approvals::Creation::Commands::Request.new(
        aggregate_id: approval_id,
        source_aggregate_type: "Customer",
        source_aggregate_id: customer_id,
        scope_id: UUID.new("00000000-0000-0000-0000-000000000001"),
        required_approvals: ["write_customers_onboarding_compliance_approval"],
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

    Customers::Reactors::Onboarding::OnApprovalCompleted.new.call(completed_event)

    aggregate = Customers::Aggregate.new(customer_id)
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
        required_approvals: ["write_customers_onboarding_compliance_approval"],
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

    # Should not raise — OnApprovalCompleted silently returns when source type != "Customer"
    Customers::Reactors::Onboarding::OnApprovalCompleted.new.call(completed_event)
  end
end
