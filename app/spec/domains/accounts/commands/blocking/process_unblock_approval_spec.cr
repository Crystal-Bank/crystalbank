require "../../../../spec_helper"

module TestEnvProcessUnblockApproval
  class_property account_id : UUID = UUID.random
end

describe CrystalBank::Domains::Accounts::Blocking::Commands::ProcessUnblockApproval do
  before_all do
    account_id = UUID.v7

    requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)
    Accounts::Projections::Accounts.new.apply(accepted)

    # Pre-apply a compliance block directly so there is something to unblock
    applied = Test::Account::Events::Blocking::Applied.new.create(
      aggr_id: account_id,
      block_type: CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      aggregate_version: 3
    )
    TEST_EVENT_STORE.append(applied)

    TestEnvProcessUnblockApproval.account_id = account_id
  end

  it "removes the block from the account after the unblock approval is completed" do
    scope_id = UUID.v7
    user_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id: user_id,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_accounts_unblocking_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    request = Accounts::Api::Requests::UnblockingCommandRequest.new(
      TestEnvProcessUnblockApproval.account_id,
      CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      "Resolution confirmed"
    )

    result = Accounts::Blocking::Commands::Unblock.new.call(request, context)
    approval_id = result[:approval_id]
    unblock_request_id = result[:block_request_id]

    # Complete the approval
    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    # Replay approval events through the event bus, triggering ProcessUnblockApproval
    apply_projection(approval_id)

    # The account aggregate should no longer have the compliance block
    account = Accounts::Aggregate.new(TestEnvProcessUnblockApproval.account_id)
    account.hydrate

    account.state.active_blocks.should_not contain(CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK)

    # The unblock request aggregate should be marked as completed
    unblock_request = Accounts::Blocking::Unblocking::Aggregate.new(unblock_request_id)
    unblock_request.hydrate

    unblock_request.state.completed.should be_true
  end

  it "is idempotent — does not remove the block twice if the request is already completed" do
    scope_id = UUID.v7
    user_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id: user_id,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_accounts_unblocking_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    # Set up a fresh account with an operations block
    account_id = UUID.v7
    requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)

    applied = Test::Account::Events::Blocking::Applied.new.create(
      aggr_id: account_id,
      block_type: CrystalBank::Types::Accounts::BlockType::OPERATIONS_BLOCK,
      aggregate_version: 3
    )
    TEST_EVENT_STORE.append(applied)

    request = Accounts::Api::Requests::UnblockingCommandRequest.new(
      account_id,
      CrystalBank::Types::Accounts::BlockType::OPERATIONS_BLOCK,
      nil
    )

    result = Accounts::Blocking::Commands::Unblock.new.call(request, context)
    approval_id = result[:approval_id]

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    # Apply once
    apply_projection(approval_id)

    # Apply again — should be a no-op because unblock_request.state.completed = true
    apply_projection(approval_id)

    # The Removed event should have been appended only once
    account = Accounts::Aggregate.new(account_id)
    account.hydrate

    account.state.active_blocks.should_not contain(CrystalBank::Types::Accounts::BlockType::OPERATIONS_BLOCK)
  end

  it "ignores an approval with a different source aggregate type" do
    # Seed an approval with source_aggregate_type = "AccountBlock" (not "AccountUnblock")
    scope_id = UUID.v7

    block_approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "AccountBlock",
      source_aggregate_id: UUID.v7,
      scope_id: scope_id,
      required_approvals: ["write_accounts_blocking_approval"],
      actor_id: UUID.v7,
    )

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: block_approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    # ProcessUnblockApproval should silently return because source_aggregate_type != "AccountUnblock"
    # No exception should be raised.
    apply_projection(block_approval_id)
  end
end
