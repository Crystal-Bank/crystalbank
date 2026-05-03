require "../../../../spec_helper"

describe CrystalBank::Domains::Users::AssignRoles::Commands::ProcessRequest do
  it "creates an approval workflow for the role assignment request" do
    user_id = UUID.v7

    onboarded = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    TEST_EVENT_STORE.append(onboarded)

    requested = Test::User::Events::AssignRoles::Requested.new.create(user_id: user_id)
    request_id = UUID.new(requested.header.aggregate_id.to_s)
    TEST_EVENT_STORE.append(requested)

    approval_id = Users::AssignRoles::Commands::ProcessRequest.new(aggregate_id: request_id).call

    apply_projection(approval_id)

    count = TEST_PROJECTION_DB.scalar(
      %(SELECT count(*) FROM "projections"."approvals" WHERE source_aggregate_type = 'UserRolesAssignment' AND source_aggregate_id = $1),
      request_id
    )
    count.should eq(1)
  end
end
