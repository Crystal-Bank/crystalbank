require "../../../spec_helper"

describe CrystalBank::Domains::Roles::Api::Roles do
  role_id = UUID.v7
  pending_role_id = UUID.v7
  available_scope_id = UUID.new("00000000-0000-0000-0000-100000000001")

  before_all do
    # Accepted role: goes through full Requested -> Accepted flow
    req = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
    acc = Test::Role::Events::Creation::Accepted.new.create(aggr_id: role_id)
    TEST_EVENT_STORE.append(req)
    TEST_EVENT_STORE.append(acc)
    Roles::Projections::Roles.new.apply(req)
    Roles::Projections::Roles.new.apply(acc)

    # Pending role: only Requested, no Accepted yet
    pending_req = Test::Role::Events::Creation::Requested.new.create(aggr_id: pending_role_id)
    TEST_EVENT_STORE.append(pending_req)
    Roles::Projections::Roles.new.apply(pending_req)
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

  describe "GET /roles - pending roles" do
    it "includes pending roles in the list" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_roles_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Roles::Queries::Roles.new.list(context, cursor: nil, limit: 100)
      results.map(&.id).should contain(pending_role_id)
    end

    it "returns 'role_creation_request' as object for pending roles" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_roles_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Roles::Queries::Roles.new.list(context, cursor: nil, limit: 100)
      pending = results.find { |r| r.id == pending_role_id }
      pending.should_not be_nil
      pending.not_nil!.accepted.should be_false
      pending.not_nil!.object.should eq("role_creation_request")
    end

    it "returns 'role' as object for accepted roles" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_roles_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Roles::Queries::Roles.new.list(context, cursor: nil, limit: 100)
      accepted = results.find { |r| r.id == role_id }
      accepted.should_not be_nil
      accepted.not_nil!.accepted.should be_true
      accepted.not_nil!.object.should eq("role")
    end
  end
end
