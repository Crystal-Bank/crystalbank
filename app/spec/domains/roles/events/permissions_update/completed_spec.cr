require "../../../../spec_helper"

describe CrystalBank::Domains::Roles::PermissionsUpdate::Events::Completed do
  it "can be initialized" do
    event = Test::Role::Events::PermissionsUpdate::Completed.new.create

    event.header.actor_id.should be_nil
    event.header.aggregate_id.should eq(UUID.new("00000000-0000-0000-0000-000000000003"))
    event.header.aggregate_type.should eq("RolePermissionsUpdate")
    event.header.aggregate_version.should eq(2)
    event.header.command_handler.should eq("test")
    event.header.event_handle.should eq("role.permissions_update.completed")
  end
end
