require "../../../../spec_helper"

module TestEnvAccountBlock
  class_property account_id : UUID = UUID.random
end

describe CrystalBank::Domains::Accounts::Blocking::Commands::Block do
  before_all do
    account_id = UUID.v7

    requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)
    Accounts::Projections::Accounts.new.apply(accepted)

    TestEnvAccountBlock.account_id = account_id
  end

  it "creates a block request and approval when account is open and block type is not active" do
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
      TestEnvAccountBlock.account_id,
      CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      "AML review"
    )

    result = Accounts::Blocking::Commands::Block.new.call(request, context)

    result[:block_request_id].should be_a(UUID)
    result[:approval_id].should be_a(UUID)

    # Verify the blocking request aggregate was created with correct state
    block_request = Accounts::Blocking::Blocking::Aggregate.new(result[:block_request_id])
    block_request.hydrate

    block_request.state.account_id.should eq(TestEnvAccountBlock.account_id)
    block_request.state.block_type.should eq(CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK)
    block_request.state.reason.should eq("AML review")
    block_request.state.completed.should be_false

    # Verify the approval was created with the correct source aggregate type
    apply_projection(result[:approval_id])
    approval = Approvals::Queries::Approvals.new.find_by_source("AccountBlock", result[:block_request_id])
    approval.should_not be_nil
    approval.not_nil!.completed.should be_false
    approval.not_nil!.required_approvals.should contain("write_accounts_blocking_approval")
  end

  it "raises when account does not exist or is not open" do
    scope_id = UUID.v7
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_accounts_blocking_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    request = Accounts::Api::Requests::BlockingCommandRequest.new(
      UUID.v7,
      CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      nil
    )

    expect_raises(CrystalBank::Exception::InvalidArgument, /does not exist or is not open/) do
      Accounts::Blocking::Commands::Block.new.call(request, context)
    end
  end

  it "raises when the block type is already active on the account" do
    scope_id = UUID.v7
    user_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id: user_id,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_accounts_blocking_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    # Pre-apply a compliance block directly onto the account aggregate
    account_id = UUID.v7
    requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)

    applied = Test::Account::Events::Blocking::Applied.new.create(
      aggr_id: account_id,
      block_type: CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      aggregate_version: 3
    )
    TEST_EVENT_STORE.append(applied)

    request = Accounts::Api::Requests::BlockingCommandRequest.new(
      account_id,
      CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      nil
    )

    expect_raises(CrystalBank::Exception::InvalidArgument, /already active/) do
      Accounts::Blocking::Commands::Block.new.call(request, context)
    end
  end

  it "raises when scope is missing from context" do
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_accounts_blocking_request,
      scope: nil,
      available_scopes: [] of UUID
    )

    request = Accounts::Api::Requests::BlockingCommandRequest.new(
      TestEnvAccountBlock.account_id,
      CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      nil
    )

    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid scope/) do
      Accounts::Blocking::Commands::Block.new.call(request, context)
    end
  end
end
