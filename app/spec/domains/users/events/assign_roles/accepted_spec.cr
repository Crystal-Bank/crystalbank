require "../../../../spec_helper"

describe CrystalBank::Domains::Users::AssignRoles::Events::Accepted do
  it "targets the User aggregate type and carries role_ids in the body" do
    user_id = UUID.v7
    role_id = UUID.v7
    event = Test::User::Events::AssignRoles::Accepted.new.create(aggr_id: user_id, role_ids: [role_id])

    event.header.aggregate_type.should eq("User")
    UUID.new(event.header.aggregate_id.to_s).should eq(user_id)
    body = event.body.as(Users::AssignRoles::Events::Accepted::Body)
    body.role_ids.should eq([role_id])
  end
end
