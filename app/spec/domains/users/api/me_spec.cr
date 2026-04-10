require "../../../spec_helper"

describe CrystalBank::Domains::Users::Api::Me do
  describe "MeResponse" do
    it "serializes scope_permissions as a sorted array of strings" do
      user_id = UUID.v7
      role_ids = [UUID.v7]
      scope_permissions = ["read_me", "read_roles_list", "write_roles_creation_request"]

      response = CrystalBank::Domains::Users::Api::Me::MeResponse.new(
        user_id: user_id,
        role_ids: role_ids,
        scope: nil,
        scope_permissions: scope_permissions
      )

      json = JSON.parse(response.to_json)
      json["scope_permissions"].as_a.map(&.as_s).should eq(scope_permissions)
    end

    it "serializes an empty scope_permissions when the user has no roles" do
      response = CrystalBank::Domains::Users::Api::Me::MeResponse.new(
        user_id: UUID.v7,
        role_ids: [] of UUID,
        scope: nil,
        scope_permissions: [] of String
      )

      json = JSON.parse(response.to_json)
      json["scope_permissions"].as_a.should be_empty
    end
  end

  describe "GET /me - scope_permissions" do
    role_id_a = UUID.v7
    role_id_b = UUID.v7

    before_all do
      event_a = Roles::Creation::Events::Requested.new(
        actor_id: UUID.v7,
        aggregate_id: role_id_a,
        name: "Role A",
        permissions: [
          CrystalBank::Permissions::READ_me,
          CrystalBank::Permissions::WRITE_users_onboarding_request,
        ],
        scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
        scopes: [UUID.new("00000000-0000-0000-0000-200000000001")],
        command_handler: "test",
        comment: "test"
      )
      event_b = Roles::Creation::Events::Requested.new(
        actor_id: UUID.v7,
        aggregate_id: role_id_b,
        name: "Role B",
        permissions: [
          CrystalBank::Permissions::READ_me,
          CrystalBank::Permissions::READ_users_list,
        ],
        scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
        scopes: [UUID.new("00000000-0000-0000-0000-200000000001")],
        command_handler: "test",
        comment: "test"
      )
      TEST_EVENT_STORE.append(event_a)
      TEST_EVENT_STORE.append(event_b)
      Roles::Projections::Roles.new.apply(event_a)
      Roles::Projections::Roles.new.apply(event_b)
    end

    it "returns merged, deduplicated, sorted permissions from all assigned roles" do
      result = Roles::Queries::RolesPermissions.new.all_permissions([role_id_a, role_id_b])
      result.should eq(["read_me", "read_users_list", "write_users_onboarding_request"])
    end

    it "returns only the permissions for the roles assigned to the user" do
      result = Roles::Queries::RolesPermissions.new.all_permissions([role_id_a])
      result.should eq(["read_me", "write_users_onboarding_request"])
    end
  end
end
