require "../../../../../spec_helper"

module TestEnvAccountClosureRequest
  class_property account_id : UUID = UUID.random
end

describe CrystalBank::Domains::Accounts::Closure::Commands::RequestHandler do
  before_all do
    account_id = UUID.v7

    requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)
    Accounts::Projections::Accounts.new.apply(accepted)

    TestEnvAccountClosureRequest.account_id = account_id
  end

  it "creates a closure request and approval when account is open and has no pending closure" do
    scope_id = UUID.v7
    user_id = UUID.v7

    result = Accounts::Closure::Commands::RequestHandler.new.handle(
      Accounts::Closure::Commands::Request.new(
        aggregate_id: TestEnvAccountClosureRequest.account_id,
        reason: CrystalBank::Types::Accounts::ClosureReason::BY_CUSTOMER,
        closure_comment: "Customer requested closure",
        actor_id: user_id, scope_id: scope_id
      )
    )

    result[:closure_request_id].should be_a(UUID)
    result[:approval_id].should be_a(UUID)

    # Verify the account aggregate is now closure-pending
    account = Accounts::Aggregate.new(TestEnvAccountClosureRequest.account_id)
    account.hydrate
    account.state.closure_pending.should be_true

    # Verify the closure request aggregate was created with correct state
    closure_request = Accounts::ClosureRequest::Aggregate.new(result[:closure_request_id])
    closure_request.hydrate

    closure_request.state.account_id.should eq(TestEnvAccountClosureRequest.account_id)
    closure_request.state.reason.should eq(CrystalBank::Types::Accounts::ClosureReason::BY_CUSTOMER)
    closure_request.state.closure_comment.should eq("Customer requested closure")
    closure_request.state.completed.should be_false

    # Verify the approval was created with the correct source aggregate type
    apply_projection(result[:approval_id])
    approval = Approvals::Queries::Approvals.new.find_by_source("AccountClosure", result[:closure_request_id])
    approval.should_not be_nil
    approval.not_nil!.completed.should be_false
    approval.not_nil!.required_approvals.should contain("write_accounts_closure_approval")
  end

  it "raises when account does not exist" do
    scope_id = UUID.v7

    expect_raises(CrystalBank::Exception::InvalidArgument, /does not exist/) do
      Accounts::Closure::Commands::RequestHandler.new.handle(
        Accounts::Closure::Commands::Request.new(
          aggregate_id: UUID.v7,
          reason: CrystalBank::Types::Accounts::ClosureReason::BY_CUSTOMER,
          closure_comment: nil,
          actor_id: UUID.v7, scope_id: scope_id
        )
      )
    end
  end

  it "raises when the account already has a pending closure request" do
    scope_id = UUID.v7
    user_id = UUID.v7

    account_id = UUID.v7
    requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)

    closure_requested = Test::Account::Events::Closure::Requested.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(closure_requested)

    expect_raises(CrystalBank::Exception::InvalidArgument, /already has a pending closure request/) do
      Accounts::Closure::Commands::RequestHandler.new.handle(
        Accounts::Closure::Commands::Request.new(
          aggregate_id: account_id,
          reason: CrystalBank::Types::Accounts::ClosureReason::BY_CUSTOMER,
          closure_comment: nil,
          actor_id: user_id, scope_id: scope_id
        )
      )
    end
  end

  it "raises when the account has virtual subaccounts that are not inactive" do
    scope_id = UUID.v7
    user_id = UUID.v7

    account_id = UUID.v7
    requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)

    virtual_account_id = UUID.v7
    virtual_requested = Test::VirtualAccount::Events::Opening::Requested.new.create(aggr_id: virtual_account_id, parent_account_id: account_id)
    VirtualAccounts::Projections::VirtualAccounts.new.apply(virtual_requested)

    expect_raises(CrystalBank::Exception::InvalidArgument, /virtual subaccounts/) do
      Accounts::Closure::Commands::RequestHandler.new.handle(
        Accounts::Closure::Commands::Request.new(
          aggregate_id: account_id,
          reason: CrystalBank::Types::Accounts::ClosureReason::BY_CUSTOMER,
          closure_comment: nil,
          actor_id: user_id, scope_id: scope_id
        )
      )
    end
  end
end
