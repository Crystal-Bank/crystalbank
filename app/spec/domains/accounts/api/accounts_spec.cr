require "../../../spec_helper"

describe CrystalBank::Domains::Accounts::Api::Accounts do
  account_id = UUID.v7
  available_scope_id = UUID.new("00000000-0000-0000-0000-300000000001")

  before_all do
    req = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    acc = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(req)
    TEST_EVENT_STORE.append(acc)
    Accounts::Projections::Accounts.new.apply(acc)
  end

  describe "GET /accounts - scope filtering" do
    it "returns the seeded account when available_scopes matches" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_accounts_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Accounts::Queries::Accounts.new.list(context, cursor: nil, limit: 100)
      results.map(&.id).should contain(account_id)
    end

    it "returns no accounts when available_scopes does not match" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_accounts_list,
        scope: UUID.v7,
        available_scopes: [UUID.v7]
      )

      results = Accounts::Queries::Accounts.new.list(context, cursor: nil, limit: 100)
      results.map(&.id).should_not contain(account_id)
    end

    it "returns no accounts when cursor is past all records" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_accounts_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Accounts::Queries::Accounts.new.list(context, cursor: UUID.new("ffffffff-ffff-ffff-ffff-ffffffffffff"), limit: 100)
      results.should be_empty
    end
  end
end
