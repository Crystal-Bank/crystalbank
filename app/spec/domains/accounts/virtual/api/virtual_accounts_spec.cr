require "../../../../spec_helper"

describe CrystalBank::Domains::Accounts::Virtual::Api::VirtualAccounts do
  parent_account_id = UUID.v7
  scope_id = UUID.new("00000000-0000-0000-0000-300000000001")
  other_scope_id = UUID.v7

  before_all do
    # Seed a parent account
    req = Test::Account::Events::Opening::Requested.new.create(aggr_id: parent_account_id)
    acc = Test::Account::Events::Opening::Accepted.new.create(aggr_id: parent_account_id)
    TEST_EVENT_STORE.append(req)
    TEST_EVENT_STORE.append(acc)
    Accounts::Projections::Accounts.new.apply(req)
    Accounts::Projections::Accounts.new.apply(acc)

    # Seed an active virtual subaccount under the parent
    virt_id = UUID.v7
    virt_req = Test::VirtualAccount::Events::Opening::Requested.new.create(
      aggr_id: virt_id,
      parent_account_id: parent_account_id,
      scope_id: scope_id
    )
    virt_acc = Test::VirtualAccount::Events::Opening::Accepted.new.create(aggr_id: virt_id)
    TEST_EVENT_STORE.append(virt_req)
    TEST_EVENT_STORE.append(virt_acc)
    Accounts::Virtual::Projections::VirtualAccounts.new.apply(virt_req)
    Accounts::Virtual::Projections::VirtualAccounts.new.apply(virt_acc)
  end

  describe "GET /accounts/:id/virtual - scope filtering" do
    it "returns the virtual subaccount when scope matches" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_accounts_virtual_list,
        scope: scope_id,
        available_scopes: [scope_id]
      )

      results = Accounts::Virtual::Queries::VirtualAccounts.new.list(parent_account_id, context, cursor: nil, limit: 100)
      results.map(&.parent_account_id).should contain(parent_account_id)
    end

    it "returns no results when scope does not match" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_accounts_virtual_list,
        scope: other_scope_id,
        available_scopes: [other_scope_id]
      )

      results = Accounts::Virtual::Queries::VirtualAccounts.new.list(parent_account_id, context, cursor: nil, limit: 100)
      results.should be_empty
    end

    it "returns no results for a different parent account" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_accounts_virtual_list,
        scope: scope_id,
        available_scopes: [scope_id]
      )

      results = Accounts::Virtual::Queries::VirtualAccounts.new.list(UUID.v7, context, cursor: nil, limit: 100)
      results.should be_empty
    end
  end
end
