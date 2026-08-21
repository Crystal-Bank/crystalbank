require "../../../../../spec_helper"

module TestEnvProcessClosureApproval
  class_property account_id : UUID = UUID.random
end

describe CrystalBank::Domains::Accounts::Reactors::Closure::OnApprovalCompleted do
  before_all do
    account_id = UUID.v7

    requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)
    Accounts::Projections::Accounts.new.apply(accepted)

    TestEnvProcessClosureApproval.account_id = account_id
  end

  it "closes the account after the closure approval is completed" do
    scope_id = UUID.v7
    user_id = UUID.v7

    result = Accounts::Closure::Commands::RequestHandler.new.handle(
      Accounts::Closure::Commands::Request.new(
        aggregate_id: TestEnvProcessClosureApproval.account_id,
        reason: CrystalBank::Types::Accounts::ClosureReason::BY_CUSTOMER,
        closure_comment: "Account no longer needed",
        actor_id: user_id, scope_id: scope_id
      )
    )
    approval_id = result[:approval_id]
    closure_request_id = result[:closure_request_id]

    # Complete the approval (Request command creates version 1 via Creation::Requested)
    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    Accounts::Reactors::Closure::OnApprovalCompleted.new.call(completed_event)

    # The account aggregate should now be closed
    account = Accounts::Aggregate.new(TestEnvProcessClosureApproval.account_id)
    account.hydrate

    account.state.open.should be_false
    account.state.closure_pending.should be_false

    # The closure request aggregate should be marked as completed
    closure_request = Accounts::ClosureRequest::Aggregate.new(closure_request_id)
    closure_request.hydrate

    closure_request.state.completed.should be_true
  end

  it "is idempotent — does not re-close the account if the request is already completed" do
    scope_id = UUID.v7
    user_id = UUID.v7

    account_id = UUID.v7
    requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)
    Accounts::Projections::Accounts.new.apply(accepted)

    result = Accounts::Closure::Commands::RequestHandler.new.handle(
      Accounts::Closure::Commands::Request.new(
        aggregate_id: account_id,
        reason: CrystalBank::Types::Accounts::ClosureReason::BY_CUSTOMER,
        closure_comment: nil,
        actor_id: user_id, scope_id: scope_id
      )
    )
    approval_id = result[:approval_id]
    closure_request_id = result[:closure_request_id]

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)
    Accounts::Reactors::Closure::OnApprovalCompleted.new.call(completed_event)

    # The closure request is now completed — the guard flag ensures future re-runs are no-ops
    closure_request = Accounts::ClosureRequest::Aggregate.new(closure_request_id)
    closure_request.hydrate
    closure_request.state.completed.should be_true

    account = Accounts::Aggregate.new(account_id)
    account.hydrate
    account.state.open.should be_false
  end

  it "ignores an approval with a different source aggregate type" do
    # Seed an approval with source_aggregate_type = "SomeUnhandledType" (not "AccountClosure")
    scope_id = UUID.v7
    source_id = UUID.v7

    other_approval_id = UUID.v7
    Approvals::Creation::Commands::RequestHandler.new.handle(
      Approvals::Creation::Commands::Request.new(
        aggregate_id: other_approval_id,
        source_aggregate_type: "SomeUnhandledType",
        source_aggregate_id: source_id,
        scope_id: scope_id,
        required_approvals: ["write_accounts_opening_compliance_approval"],
        actor_id: UUID.v7,
      )
    )

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: other_approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    # OnApprovalCompleted should silently return because source_aggregate_type != "AccountClosure".
    # No exception should be raised.
    Accounts::Reactors::Closure::OnApprovalCompleted.new.call(completed_event)
  end
end
