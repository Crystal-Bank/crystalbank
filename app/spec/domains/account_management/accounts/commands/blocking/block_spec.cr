require "../../../../../spec_helper"

module TestEnvAccountBlock
  class_property account_id : UUID = UUID.random
end

describe CrystalBank::Domains::Accounts::Blocking::Commands::BlockHandler do
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

    result = Accounts::Blocking::Commands::BlockHandler.new.handle(
      Accounts::Blocking::Commands::Block.new(
        aggregate_id: UUID.v7, account_id: TestEnvAccountBlock.account_id,
        block_type: CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK, reason: "AML review",
        actor_id: user_id, scope_id: scope_id
      )
    )

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

    subject = approval.not_nil!.subject
    subject.should_not be_nil
    subject.not_nil!.title.should eq("Account Block")
    subject.not_nil!.summary.should contain("compliance_block")
    field_labels = subject.not_nil!.fields.map(&.label)
    field_labels.should contain("Account")
    field_labels.should contain("Block Type")
    field_labels.should contain("Reason")
    reason_field = subject.not_nil!.fields.find { |f| f.label == "Reason" }
    reason_field.not_nil!.value.should eq("AML review")
  end

  it "raises when account does not exist or is not open" do
    scope_id = UUID.v7

    expect_raises(CrystalBank::Exception::InvalidArgument, /does not exist or is not open/) do
      Accounts::Blocking::Commands::BlockHandler.new.handle(
        Accounts::Blocking::Commands::Block.new(
          aggregate_id: UUID.v7, account_id: UUID.v7,
          block_type: CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK, reason: nil,
          actor_id: UUID.v7, scope_id: scope_id
        )
      )
    end
  end

  it "raises when the block type is already active on the account" do
    scope_id = UUID.v7
    user_id = UUID.v7

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

    expect_raises(CrystalBank::Exception::InvalidArgument, /already active/) do
      Accounts::Blocking::Commands::BlockHandler.new.handle(
        Accounts::Blocking::Commands::Block.new(
          aggregate_id: UUID.v7, account_id: account_id,
          block_type: CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK, reason: nil,
          actor_id: user_id, scope_id: scope_id
        )
      )
    end
  end
end
