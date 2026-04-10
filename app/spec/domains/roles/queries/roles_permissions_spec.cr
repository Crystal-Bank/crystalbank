require "../../../spec_helper"

describe CrystalBank::Domains::Roles::Queries::RolesPermissions do
  describe "#all_permissions" do
    it "returns an empty array when no role IDs are provided" do
      result = Roles::Queries::RolesPermissions.new.all_permissions([] of UUID)
      result.should be_empty
    end

    it "returns an empty array when no matching roles exist in the database" do
      result = Roles::Queries::RolesPermissions.new.all_permissions([UUID.v7])
      result.should be_empty
    end

    it "returns sorted permissions for a single role" do
      role_id = UUID.v7

      event = Roles::Creation::Events::Requested.new(
        actor_id: UUID.v7,
        aggregate_id: role_id,
        name: "Test Role",
        permissions: [
          CrystalBank::Permissions::WRITE_roles_creation_request,
          CrystalBank::Permissions::READ_roles_list,
        ],
        scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
        scopes: [UUID.new("00000000-0000-0000-0000-200000000001")],
        command_handler: "test",
        comment: "test"
      )
      TEST_EVENT_STORE.append(event)
      Roles::Projections::Roles.new.apply(event)

      result = Roles::Queries::RolesPermissions.new.all_permissions([role_id])
      result.should eq(["read_roles_list", "write_roles_creation_request"])
    end

    it "merges, deduplicates, and sorts permissions from multiple roles" do
      role_id_1 = UUID.v7
      role_id_2 = UUID.v7

      event_1 = Roles::Creation::Events::Requested.new(
        actor_id: UUID.v7,
        aggregate_id: role_id_1,
        name: "Role A",
        permissions: [
          CrystalBank::Permissions::WRITE_roles_creation_request,
          CrystalBank::Permissions::READ_users_list,
        ],
        scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
        scopes: [UUID.new("00000000-0000-0000-0000-200000000001")],
        command_handler: "test",
        comment: "test"
      )
      event_2 = Roles::Creation::Events::Requested.new(
        actor_id: UUID.v7,
        aggregate_id: role_id_2,
        name: "Role B",
        permissions: [
          CrystalBank::Permissions::READ_users_list,
          CrystalBank::Permissions::READ_me,
        ],
        scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
        scopes: [UUID.new("00000000-0000-0000-0000-200000000001")],
        command_handler: "test",
        comment: "test"
      )
      TEST_EVENT_STORE.append(event_1)
      TEST_EVENT_STORE.append(event_2)
      Roles::Projections::Roles.new.apply(event_1)
      Roles::Projections::Roles.new.apply(event_2)

      result = Roles::Queries::RolesPermissions.new.all_permissions([role_id_1, role_id_2])
      result.should eq(["read_me", "read_users_list", "write_roles_creation_request"])
    end

    it "ignores role IDs not present in the database when mixed with valid ones" do
      role_id = UUID.v7

      event = Roles::Creation::Events::Requested.new(
        actor_id: UUID.v7,
        aggregate_id: role_id,
        name: "Role C",
        permissions: [CrystalBank::Permissions::READ_accounts_list],
        scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
        scopes: [UUID.new("00000000-0000-0000-0000-200000000001")],
        command_handler: "test",
        comment: "test"
      )
      TEST_EVENT_STORE.append(event)
      Roles::Projections::Roles.new.apply(event)

      result = Roles::Queries::RolesPermissions.new.all_permissions([role_id, UUID.v7])
      result.should eq(["read_accounts_list"])
    end
  end
end
