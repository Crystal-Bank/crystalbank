require "../../../spec_helper"

describe CrystalBank::Domains::Users::Api::Users do
  user_id = UUID.v7
  available_scope_id = UUID.new("00000000-0000-0000-0000-100000000001")

  before_all do
    req = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    acc = Test::User::Events::Onboarding::Accepted.new.create(aggr_id: user_id)
    TEST_EVENT_STORE.append(req)
    TEST_EVENT_STORE.append(acc)
    Users::Projections::Users.new.apply(acc)
  end

  describe "GET /users - scope filtering" do
    it "returns the seeded user when available_scopes matches" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_users_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Users::Queries::Users.new.list(context, cursor: nil, limit: 100)
      results.map(&.id).should contain(user_id)
    end

    it "returns no users when available_scopes does not match" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_users_list,
        scope: UUID.v7,
        available_scopes: [UUID.v7]
      )

      results = Users::Queries::Users.new.list(context, cursor: nil, limit: 100)
      results.map(&.id).should_not contain(user_id)
    end

    it "returns no users when cursor is past all records" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_users_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Users::Queries::Users.new.list(context, cursor: UUID.new("ffffffff-ffff-ffff-ffff-ffffffffffff"), limit: 100)
      results.should be_empty
    end
  end
end
