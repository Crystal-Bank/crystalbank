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

  it "creates an approval with a subject snapshot containing user and role count" do
    user_id = UUID.v7

    onboarded = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    TEST_EVENT_STORE.append(onboarded)

    requested = Test::User::Events::AssignRoles::Requested.new.create(user_id: user_id)
    request_id = UUID.new(requested.header.aggregate_id.to_s)
    TEST_EVENT_STORE.append(requested)

    approval_id = Users::AssignRoles::Commands::ProcessRequest.new(aggregate_id: request_id).call
    apply_projection(approval_id)

    approval = Approvals::Queries::Approvals.new.find_by_source("UserRolesAssignment", request_id)
    approval.should_not be_nil

    subject = approval.not_nil!.subject
    subject.should_not be_nil
    subject.not_nil!.title.should eq("Role Assignment")
    subject.not_nil!.summary.should contain("Peter Pan")
    subject.not_nil!.summary.should contain("1 role(s)")
    field_labels = subject.not_nil!.fields.map(&.label)
    field_labels.should contain("User")
    field_labels.should contain("Roles")
    subject.not_nil!.fields.find { |f| f.label == "User" }.not_nil!.value.should eq("Peter Pan")
    subject.not_nil!.fields.find { |f| f.label == "Roles" }.not_nil!.value.should eq("1")
  end
end
