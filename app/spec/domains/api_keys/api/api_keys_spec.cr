require "../../../spec_helper"

describe CrystalBank::Domains::ApiKeys::Api::ApiKeys do
  active_key_id = UUID.v7
  revoked_key_id = UUID.v7
  available_scope_id = UUID.new("00000000-0000-0000-0000-000000000001")

  before_all do
    # Seed an active key
    req_active = Test::ApiKey::Events::Generation::Requested.new.create(aggr_id: active_key_id)
    acc_active = Test::ApiKey::Events::Generation::Accepted.new.create(aggr_id: active_key_id)
    TEST_EVENT_STORE.append(req_active)
    TEST_EVENT_STORE.append(acc_active)
    ApiKeys::Projections::ApiKeys.new.apply(req_active)
    ApiKeys::Projections::ApiKeys.new.apply(acc_active)

    # Seed a revoked key
    req_revoked = Test::ApiKey::Events::Generation::Requested.new.create(aggr_id: revoked_key_id)
    acc_revoked = Test::ApiKey::Events::Generation::Accepted.new.create(aggr_id: revoked_key_id)
    TEST_EVENT_STORE.append(req_revoked)
    TEST_EVENT_STORE.append(acc_revoked)
    ApiKeys::Projections::ApiKeys.new.apply(req_revoked)
    ApiKeys::Projections::ApiKeys.new.apply(acc_revoked)

    rev_req = Test::ApiKey::Events::Revocation::Requested.new.create(aggr_id: revoked_key_id, version: 3)
    rev_acc = Test::ApiKey::Events::Revocation::Accepted.new.create(aggr_id: revoked_key_id, version: 4)
    TEST_EVENT_STORE.append(rev_req)
    TEST_EVENT_STORE.append(rev_acc)
    ApiKeys::Projections::ApiKeys.new.apply(rev_acc)
  end

  describe "GET /api_keys - scope filtering" do
    it "returns the seeded key when available_scopes matches" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_api_keys_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = ApiKeys::Queries::ApiKeys.new.list(context, cursor: nil, limit: 100)
      results.map(&.id).should contain(active_key_id)
    end

    it "returns no keys when available_scopes does not match" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_api_keys_list,
        scope: UUID.v7,
        available_scopes: [UUID.v7]
      )

      results = ApiKeys::Queries::ApiKeys.new.list(context, cursor: nil, limit: 100)
      results.map(&.id).should_not contain(active_key_id)
    end

    it "returns no keys when cursor is past all records" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_api_keys_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = ApiKeys::Queries::ApiKeys.new.list(context, cursor: UUID.new("ffffffff-ffff-ffff-ffff-ffffffffffff"), limit: 100)
      results.should be_empty
    end

    it "returns both active and revoked keys in the listing" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_api_keys_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = ApiKeys::Queries::ApiKeys.new.list(context, cursor: nil, limit: 100)
      ids = results.map(&.id)
      ids.should contain(active_key_id)
      ids.should contain(revoked_key_id)

      active = results.find { |k| k.id == active_key_id }.not_nil!
      revoked = results.find { |k| k.id == revoked_key_id }.not_nil!
      active.status.should eq("active")
      revoked.status.should eq("revoked")
    end
  end
end
