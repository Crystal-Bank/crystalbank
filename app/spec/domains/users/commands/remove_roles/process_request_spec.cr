require "../../../../spec_helper"

describe CrystalBank::Domains::Users::RemoveRoles::Commands::ProcessRequest do
  it "creates an approval with a subject snapshot containing user and role count" do
    user_id = UUID.v7
    role_id = UUID.v7

    onboarded = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    TEST_EVENT_STORE.append(onboarded)

    requested = Users::RemoveRoles::Events::Requested.new(
      actor_id: UUID.new("00000000-0000-0000-0000-000000000000"),
      command_handler: "test",
      user_id: user_id,
      role_ids: [role_id],
      scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
    )
    request_id = UUID.new(requested.header.aggregate_id.to_s)
    TEST_EVENT_STORE.append(requested)

    approval_id = Users::RemoveRoles::Commands::ProcessRequest.new(aggregate_id: request_id).call
    apply_projection(approval_id)

    approval = Approvals::Queries::Approvals.new.find_by_source("UserRolesRemoval", request_id)
    approval.should_not be_nil
    approval.not_nil!.required_approvals.should contain("write_users_remove_roles_approval")

    subject = approval.not_nil!.subject
    subject.should_not be_nil
    subject.not_nil!.title.should eq("Role Removal")
    subject.not_nil!.summary.should contain("Peter Pan")
    subject.not_nil!.summary.should contain("1 role(s)")
    field_labels = subject.not_nil!.fields.map(&.label)
    field_labels.should contain("User")
    field_labels.should contain("Roles")
    subject.not_nil!.fields.find { |f| f.label == "User" }.not_nil!.value.should eq("Peter Pan")
    subject.not_nil!.fields.find { |f| f.label == "Roles" }.not_nil!.value.should eq("1")
  end
end
