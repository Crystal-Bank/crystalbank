require "../../../../../spec_helper"

private def seed_active_account(scope_id : UUID) : UUID
  account_id = UUID.v7
  req = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
  acc = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
  TEST_EVENT_STORE.append(req)
  TEST_EVENT_STORE.append(acc)
  Accounts::Projections::Accounts.new.apply(req)
  Accounts::Projections::Accounts.new.apply(acc)
  account_id
end

private def make_virtual_opening_request(name : String) : VirtualAccounts::Api::Requests::VirtualOpeningRequest
  VirtualAccounts::Api::Requests::VirtualOpeningRequest.from_json({"name" => name}.to_json)
end

describe CrystalBank::Domains::VirtualAccounts::Opening::Commands::RequestHandler do
  actor_id = UUID.v7

  it "raises when parent account does not exist" do
    request = make_virtual_opening_request("Reserves")

    expect_raises(CrystalBank::Exception::InvalidArgument, /does not exist/) do
      VirtualAccounts::Opening::Commands::RequestHandler.new.handle(
        VirtualAccounts::Opening::Commands::Request.new(aggregate_id: UUID.v7, name: request.name, parent_account_id: UUID.v7, actor_id: actor_id)
      )
    end
  end

  it "raises when parent account is not active (pending_approval)" do
    account_id = UUID.v7
    req = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(req)
    Accounts::Projections::Accounts.new.apply(req)

    request = make_virtual_opening_request("Reserves")

    expect_raises(CrystalBank::Exception::InvalidArgument, /not active/) do
      VirtualAccounts::Opening::Commands::RequestHandler.new.handle(
        VirtualAccounts::Opening::Commands::Request.new(aggregate_id: UUID.v7, name: request.name, parent_account_id: account_id, actor_id: actor_id)
      )
    end
  end

  it "raises when parent is itself a virtual account" do
    scope_id = UUID.new("00000000-0000-0000-0000-300000000001")
    parent_id = seed_active_account(scope_id)
    virtual_id = UUID.v7
    virt_req = Test::VirtualAccount::Events::Opening::Requested.new.create(aggr_id: virtual_id, parent_account_id: parent_id, scope_id: scope_id)
    virt_acc = Test::VirtualAccount::Events::Opening::Accepted.new.create(aggr_id: virtual_id)
    TEST_EVENT_STORE.append(virt_req)
    TEST_EVENT_STORE.append(virt_acc)
    VirtualAccounts::Projections::VirtualAccounts.new.apply(virt_req)
    VirtualAccounts::Projections::VirtualAccounts.new.apply(virt_acc)

    request = make_virtual_opening_request("Sub-Reserves")

    expect_raises(CrystalBank::Exception::InvalidArgument, /does not exist/) do
      VirtualAccounts::Opening::Commands::RequestHandler.new.handle(
        VirtualAccounts::Opening::Commands::Request.new(aggregate_id: UUID.v7, name: request.name, parent_account_id: virtual_id, actor_id: actor_id)
      )
    end
  end

  it "creates a virtual account opening request when parent account is active" do
    scope_id = UUID.new("00000000-0000-0000-0000-300000000001")
    account_id = seed_active_account(scope_id)
    request = make_virtual_opening_request("Reserves")
    aggregate_id = UUID.v7

    VirtualAccounts::Opening::Commands::RequestHandler.new.handle(
      VirtualAccounts::Opening::Commands::Request.new(aggregate_id: aggregate_id, name: request.name, parent_account_id: account_id, actor_id: actor_id)
    )

    aggregate = VirtualAccounts::Aggregate.new(aggregate_id)
    aggregate.hydrate
    aggregate.state.name.should eq("Reserves")
  end
end
