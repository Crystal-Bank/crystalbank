require "../../../../spec_helper"

describe CrystalBank::Domains::Roles::PermissionsUpdate::Events::Requested do
  it "can be initialized" do
    event = Test::Role::Events::PermissionsUpdate::Requested.new.create

    event.header.actor_id.should eq(UUID.new("00000000-0000-0000-0000-000000000000"))
    event.header.aggregate_id.should eq(UUID.new("00000000-0000-0000-0000-000000000003"))
    event.header.aggregate_type.should eq("RolePermissionsUpdate")
    event.header.command_handler.should eq("test")
    event.header.event_handle.should eq("role.permissions_update.requested")

    body = event.body.as(Roles::PermissionsUpdate::Events::Requested::Body)
    body.role_id.should eq(UUID.new("00000000-0000-0000-0000-000000000001"))
    body.permissions.should eq([CrystalBank::Permissions::WRITE_roles_permissions_update_request])
  end

  it "can serialize and deserialize from json" do
    event = Test::Role::Events::PermissionsUpdate::Requested.new.create
    h = event.header

    b = event.body.as(Roles::PermissionsUpdate::Events::Requested::Body)
    json_body = b.to_json

    e = Roles::PermissionsUpdate::Events::Requested.new(h, JSON.parse(json_body))
    json_body.should eq(e.body.to_json)
  end
end
