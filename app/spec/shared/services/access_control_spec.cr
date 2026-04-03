require "../../spec_helper"

describe CrystalBank::Services::AccessControl do
  # Two deliberately disjoint scope UUIDs:
  #   role_scope_id    — the scope the role grants access to
  #   request_scope_id — the scope the client requests (no overlap with the role's scopes)
  #
  # With `&&` (the bug), available_scopes returns `request_scopes_tree` whenever
  # `roles_scopes_tree` is non-empty — granting access to a scope that the role
  # never covered.  With `&` (the fix) the intersection is empty, correctly
  # denying access.
  role_scope_id = UUID.new("00000000-0000-0000-ac00-000000000001")
  request_scope_id = UUID.new("00000000-0000-0000-ac00-000000000002")
  role_id = UUID.new("00000000-0000-0000-ac00-000000000003")
  permission = CrystalBank::Permissions::READ_roles_list

  before_all do
    TEST_PROJECTION_DB.exec %(
      INSERT INTO projections.scopes (uuid, aggregate_version, scope_id, created_at, name)
      VALUES ($1, 1, $1, NOW(), 'AC Test - Role Scope')
      ON CONFLICT (uuid) DO NOTHING
    ), role_scope_id

    TEST_PROJECTION_DB.exec %(
      INSERT INTO projections.scopes (uuid, aggregate_version, scope_id, created_at, name)
      VALUES ($1, 1, $1, NOW(), 'AC Test - Request Scope')
      ON CONFLICT (uuid) DO NOTHING
    ), request_scope_id

    TEST_PROJECTION_DB.exec %(
      INSERT INTO projections.roles (uuid, aggregate_version, scope_id, created_at, name, permissions, scopes)
      VALUES ($1, 1, $2, NOW(), 'AC Test Role', $3::jsonb, $4::jsonb)
      ON CONFLICT (uuid) DO NOTHING
    ), role_id, role_scope_id, [permission.to_s].to_json, [role_scope_id.to_s].to_json
  end

  describe "#available_scopes" do
    context "when the request scope does not intersect the role's granted scopes" do
      it "returns an empty array" do
        access = CrystalBank::Services::AccessControl.new(roles: [role_id])
        result = access.available_scopes(permission, request_scope_id)
        result.should be_empty
      end
    end

    context "when the request scope intersects the role's granted scopes" do
      it "returns only the intersecting scopes" do
        access = CrystalBank::Services::AccessControl.new(roles: [role_id])
        result = access.available_scopes(permission, role_scope_id)
        result.should contain(role_scope_id)
        result.should_not contain(request_scope_id)
      end
    end

    context "when no request scope is given" do
      it "returns all scopes granted by the role" do
        access = CrystalBank::Services::AccessControl.new(roles: [role_id])
        result = access.available_scopes(permission, nil)
        result.should contain(role_scope_id)
      end
    end
  end
end
