require "../../../../spec_helper"

module TestEnvAccountUnblock
  class_property account_id : UUID = UUID.random
end

describe CrystalBank::Domains::Accounts::Blocking::Commands::Unblock do
  before_all do
    account_id = UUID.v7

    requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)

    # Pre-apply a compliance block so the unblock command can act on it
    applied = Test::Account::Events::Blocking::Applied.new.create(
      aggr_id: account_id,
      block_type: CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      aggregate_version: 3
    )
    TEST_EVENT_STORE.append(applied)

    TestEnvAccountUnblock.account_id = account_id
  end

  it "creates an unblock request and approval when account has the block active" do
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
      TestEnvAccountUnblock.account_id,
      CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      "Block resolved"
    )

    result = Accounts::Blocking::Commands::Unblock.new.call(request, context)

    result[:block_request_id].should be_a(UUID)
    result[:approval_id].should be_a(UUID)

    # Verify the unblocking request aggregate was created with correct state
    unblock_request = Accounts::Blocking::Unblocking::Aggregate.new(result[:block_request_id])
    unblock_request.hydrate

    unblock_request.state.account_id.should eq(TestEnvAccountUnblock.account_id)
    unblock_request.state.block_type.should eq(CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK)
    unblock_request.state.reason.should eq("Block resolved")
    unblock_request.state.completed.should be_false

    # Verify the approval was created with the correct source aggregate type
    apply_projection(result[:approval_id])
    approval = Approvals::Queries::Approvals.new.find_by_source("AccountUnblock", result[:block_request_id])
    approval.should_not be_nil
    approval.not_nil!.completed.should be_false
    approval.not_nil!.required_approvals.should contain("write_accounts_unblocking_approval")
  end

  it "raises when account does not exist or is not open" do
    scope_id = UUID.v7
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_accounts_unblocking_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    request = Accounts::Api::Requests::UnblockingCommandRequest.new(
      UUID.v7,
      CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      nil
    )

    expect_raises(CrystalBank::Exception::InvalidArgument, /does not exist or is not open/) do
      Accounts::Blocking::Commands::Unblock.new.call(request, context)
    end
  end

  it "raises when the block type is not active on the account" do
    scope_id = UUID.v7
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_accounts_unblocking_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    # Open a fresh account with no active blocks
    account_id = UUID.v7
    requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)

    request = Accounts::Api::Requests::UnblockingCommandRequest.new(
      account_id,
      CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      nil
    )

    expect_raises(CrystalBank::Exception::InvalidArgument, /is not active/) do
      Accounts::Blocking::Commands::Unblock.new.call(request, context)
    end
  end

  it "raises when scope is missing from context" do
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_accounts_unblocking_request,
      scope: nil,
      available_scopes: [] of UUID
    )

    request = Accounts::Api::Requests::UnblockingCommandRequest.new(
      TestEnvAccountUnblock.account_id,
      CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      nil
    )

    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid scope/) do
      Accounts::Blocking::Commands::Unblock.new.call(request, context)
    end
  end
end
