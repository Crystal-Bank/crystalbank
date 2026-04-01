require "../../../spec_helper"

describe CrystalBank::Domains::Scopes::Api::Scopes do
  scope_item_id = UUID.v7
  available_scope_id = UUID.new("00000000-0000-0000-0000-100000000001")

  before_all do
    req = Test::Scope::Events::Creation::Requested.new.create(aggr_id: scope_item_id)
    acc = Test::Scope::Events::Creation::Accepted.new.create(aggr_id: scope_item_id)
    TEST_EVENT_STORE.append(req)
    TEST_EVENT_STORE.append(acc)
    Scopes::Projections::Scopes.new.apply(acc)
  end

  describe "GET /scopes - scope filtering" do
    it "returns the seeded scope when available_scopes matches" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_scopes_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Scopes::Queries::Scopes.new.list(context, cursor: nil, limit: 100)
      results.map(&.id).should contain(scope_item_id)
    end

    it "returns no scopes when available_scopes does not match" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_scopes_list,
        scope: UUID.v7,
        available_scopes: [UUID.v7]
      )

      results = Scopes::Queries::Scopes.new.list(context, cursor: nil, limit: 100)
      results.map(&.id).should_not contain(scope_item_id)
    end

    it "returns no scopes when cursor is past all records" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_scopes_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Scopes::Queries::Scopes.new.list(context, cursor: UUID.new("ffffffff-ffff-ffff-ffff-ffffffffffff"), limit: 100)
      results.should be_empty
    end
  end
end
