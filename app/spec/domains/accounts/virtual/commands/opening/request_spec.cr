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

private def make_virtual_opening_context(scope_id : UUID) : CrystalBank::Api::Context
  CrystalBank::Api::Context.new(
    user_id: UUID.v7,
    roles: [] of UUID,
    required_permission: CrystalBank::Permissions::WRITE_accounts_virtual_opening_request,
    scope: scope_id,
    available_scopes: [scope_id]
  )
end

private def make_virtual_opening_request(name : String) : Accounts::Virtual::Api::Requests::VirtualOpeningRequest
  Accounts::Virtual::Api::Requests::VirtualOpeningRequest.from_json({"name" => name}.to_json)
end

describe CrystalBank::Domains::Accounts::Virtual::Opening::Commands::Request do
  scope_id = UUID.new("00000000-0000-0000-0000-300000000001")

  it "raises when parent account does not exist" do
    context = make_virtual_opening_context(scope_id)
    request = make_virtual_opening_request("Reserves")

    expect_raises(CrystalBank::Exception::InvalidArgument, /does not exist/) do
      Accounts::Virtual::Opening::Commands::Request.new.call(request, UUID.v7, context)
    end
  end

  it "raises when parent account is not active (pending_approval)" do
    account_id = UUID.v7
    req = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(req)
    Accounts::Projections::Accounts.new.apply(req)

    context = make_virtual_opening_context(scope_id)
    request = make_virtual_opening_request("Reserves")

    expect_raises(CrystalBank::Exception::InvalidArgument, /not active/) do
      Accounts::Virtual::Opening::Commands::Request.new.call(request, account_id, context)
    end
  end

  it "raises when parent is itself a virtual account" do
    parent_id = seed_active_account(scope_id)
    virtual_id = UUID.v7
    virt_req = Test::VirtualAccount::Events::Opening::Requested.new.create(aggr_id: virtual_id, parent_account_id: parent_id, scope_id: scope_id)
    virt_acc = Test::VirtualAccount::Events::Opening::Accepted.new.create(aggr_id: virtual_id)
    TEST_EVENT_STORE.append(virt_req)
    TEST_EVENT_STORE.append(virt_acc)
    Accounts::Virtual::Projections::VirtualAccounts.new.apply(virt_req)
    Accounts::Virtual::Projections::VirtualAccounts.new.apply(virt_acc)

    context = make_virtual_opening_context(scope_id)
    request = make_virtual_opening_request("Sub-Reserves")

    expect_raises(CrystalBank::Exception::InvalidArgument, /does not exist/) do
      Accounts::Virtual::Opening::Commands::Request.new.call(request, virtual_id, context)
    end
  end

  it "creates a virtual account opening request when parent account is active" do
    account_id = seed_active_account(scope_id)
    context = make_virtual_opening_context(scope_id)
    request = make_virtual_opening_request("Reserves")

    result = Accounts::Virtual::Opening::Commands::Request.new.call(request, account_id, context)
    result.should be_a(UUID)
  end
end
