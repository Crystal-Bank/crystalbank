require "../../../../spec_helper"

describe CrystalBank::Domains::Users::AssignRoles::Events::Requested do
  it "targets the UserRolesAssignment aggregate type" do
    role_id = UUID.v7
    user_id = UUID.v7
    event = Test::User::Events::AssignRoles::Requested.new.create(user_id: user_id, role_ids: [role_id])

    event.header.aggregate_type.should eq("UserRolesAssignment")
    body = event.body.as(Users::AssignRoles::Events::Requested::Body)
    body.user_id.should eq(user_id)
    body.role_ids.should eq([role_id])
  end

  it "auto-generates a distinct aggregate ID (the request aggregate, not the user)" do
    user_id = UUID.v7
    event = Test::User::Events::AssignRoles::Requested.new.create(user_id: user_id)

    UUID.new(event.header.aggregate_id.to_s).should_not eq(user_id)
  end
end
