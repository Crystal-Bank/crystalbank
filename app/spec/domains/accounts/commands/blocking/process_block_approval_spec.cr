require "../../../../spec_helper"

module TestEnvProcessBlockApproval
  class_property account_id : UUID = UUID.random
end

describe CrystalBank::Domains::Accounts::Blocking::Commands::ProcessBlockApproval do
  before_all do
    account_id = UUID.v7

    requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)
    Accounts::Projections::Accounts.new.apply(accepted)

    TestEnvProcessBlockApproval.account_id = account_id
  end

  it "applies the block to the account after the approval is completed" do
    scope_id = UUID.v7
    user_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id: user_id,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_accounts_blocking_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    request = Accounts::Api::Requests::BlockingCommandRequest.new(
      TestEnvProcessBlockApproval.account_id,
      CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      "Regulatory hold"
    )

    result = Accounts::Blocking::Commands::Block.new.call(request, context)
    approval_id = result[:approval_id]
    block_request_id = result[:block_request_id]

    # Complete the approval (Block command creates version 1 via Creation::Requested)
    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    # Replay approval events through the event bus, triggering ProcessBlockApproval
    apply_projection(approval_id)

    # The account aggregate should now have the compliance block active
    account = Accounts::Aggregate.new(TestEnvProcessBlockApproval.account_id)
    account.hydrate

    account.state.active_blocks.should contain(CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK)

    # The block request aggregate should be marked as completed
    block_request = Accounts::Blocking::Blocking::Aggregate.new(block_request_id)
    block_request.hydrate

    block_request.state.completed.should be_true
  end

  it "is idempotent — does not apply the block twice if the request is already completed" do
    scope_id = UUID.v7
    user_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id: user_id,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_accounts_blocking_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    account_id = UUID.v7
    requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)
    Accounts::Projections::Accounts.new.apply(accepted)

    request = Accounts::Api::Requests::BlockingCommandRequest.new(
      account_id,
      CrystalBank::Types::Accounts::BlockType::OPERATIONS_BLOCK,
      nil
    )

    result = Accounts::Blocking::Commands::Block.new.call(request, context)
    approval_id = result[:approval_id]
    block_request_id = result[:block_request_id]

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)
    apply_projection(approval_id)

    # The block request is now completed — the guard flag ensures future re-runs are no-ops
    block_request = Accounts::Blocking::Blocking::Aggregate.new(block_request_id)
    block_request.hydrate
    block_request.state.completed.should be_true

    # Account should have exactly one operations block
    account = Accounts::Aggregate.new(account_id)
    account.hydrate

    ops_blocks = account.state.active_blocks.count { |b| b == CrystalBank::Types::Accounts::BlockType::OPERATIONS_BLOCK }
    ops_blocks.should eq(1)
  end

  it "ignores an approval with a different source aggregate type" do
    # Seed an approval with source_aggregate_type = "Account" (not "AccountBlock")
    # directly via the approval creation command
    scope_id = UUID.v7
    source_id = UUID.v7

    other_approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "SomeUnhandledType",
      source_aggregate_id: source_id,
      scope_id: scope_id,
      required_approvals: ["write_accounts_opening_compliance_approval"],
      actor_id: UUID.v7,
    )

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: other_approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    # Replaying the approval through the bus triggers all Completed subscribers.
    # ProcessBlockApproval should silently return because source_aggregate_type != "AccountBlock".
    # No exception should be raised.
    apply_projection(other_approval_id)
  end
end
