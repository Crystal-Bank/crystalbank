require "../../../spec_helper"

describe CrystalBank::Domains::Roles::Api::Roles do
  role_id = UUID.v7
  available_scope_id = UUID.new("00000000-0000-0000-0000-100000000001")

  before_all do
    req = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
    acc = Test::Role::Events::Creation::Accepted.new.create(aggr_id: role_id)
    TEST_EVENT_STORE.append(req)
    TEST_EVENT_STORE.append(acc)
    Roles::Projections::Roles.new.apply(acc)
  end

  describe "GET /roles - scope filtering" do
    it "returns the seeded role when available_scopes matches" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_roles_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Roles::Queries::Roles.new.list(context, cursor: nil, limit: 100)
      results.map(&.id).should contain(role_id)
    end

    it "returns no roles when available_scopes does not match" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_roles_list,
        scope: UUID.v7,
        available_scopes: [UUID.v7]
      )

      results = Roles::Queries::Roles.new.list(context, cursor: nil, limit: 100)
      results.map(&.id).should_not contain(role_id)
    end

    it "returns no roles when cursor is past all records" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_roles_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Roles::Queries::Roles.new.list(context, cursor: UUID.new("ffffffff-ffff-ffff-ffff-ffffffffffff"), limit: 100)
      results.should be_empty
    end
  end
end
