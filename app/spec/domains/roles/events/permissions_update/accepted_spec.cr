require "../../../../spec_helper"

describe CrystalBank::Domains::Roles::PermissionsUpdate::Events::Accepted do
  it "can be initialized" do
    event = Test::Role::Events::PermissionsUpdate::Accepted.new.create

    event.header.actor_id.should eq(UUID.new("00000000-0000-0000-0000-000000000000"))
    event.header.aggregate_id.should eq(UUID.new("00000000-0000-0000-0000-000000000001"))
    event.header.aggregate_type.should eq("Role")
    event.header.aggregate_version.should eq(3)
    event.header.command_handler.should eq("test")
    event.header.event_handle.should eq("role.permissions_update.accepted")

    body = event.body.as(Roles::PermissionsUpdate::Events::Accepted::Body)
    body.permissions.should eq([CrystalBank::Permissions::WRITE_roles_permissions_update_request])
  end

  it "can serialize to json" do
    object = Test::Role::Events::PermissionsUpdate::Accepted.new
    event = object.create

    b = event.body.as(Roles::PermissionsUpdate::Events::Accepted::Body)
    b.to_json.should eq(object.json_string)
  end

  it "can serialize and deserialize from json" do
    event = Test::Role::Events::PermissionsUpdate::Accepted.new.create
    h = event.header

    b = event.body.as(Roles::PermissionsUpdate::Events::Accepted::Body)
    json_body = b.to_json

    e = Roles::PermissionsUpdate::Events::Accepted.new(h, JSON.parse(json_body))
    json_body.should eq(e.body.to_json)
  end
end
