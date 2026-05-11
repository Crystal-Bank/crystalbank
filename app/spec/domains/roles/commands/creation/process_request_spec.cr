require "../../../../spec_helper"

describe CrystalBank::Domains::Roles::Creation::Commands::ProcessRequest do
  it "does not accept the role before approval" do
    role_id = UUID.v7

    event = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
    TEST_EVENT_STORE.append(event)

    Roles::Creation::Commands::ProcessRequest.new(aggregate_id: role_id).call

    aggregate = Roles::Aggregate.new(role_id)
    aggregate.hydrate

    aggregate.state.aggregate_version.should eq(1)
  end

  it "creates an approval with a subject snapshot containing name and scope" do
    role_id = UUID.v7

    event = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
    TEST_EVENT_STORE.append(event)

    approval_id = Roles::Creation::Commands::ProcessRequest.new(aggregate_id: role_id).call
    apply_projection(approval_id)

    approval = Approvals::Queries::Approvals.new.find_by_source("Role", role_id)
    approval.should_not be_nil
    approval.not_nil!.required_approvals.should contain("write_roles_creation_approval")

    subject = approval.not_nil!.subject
    subject.should_not be_nil
    subject.not_nil!.title.should eq("Role Creation")
    subject.not_nil!.summary.should eq("Scope name test")
    field_labels = subject.not_nil!.fields.map(&.label)
    field_labels.should contain("Name")
    field_labels.should contain("Scope")
    subject.not_nil!.fields.find { |f| f.label == "Name" }.not_nil!.value.should eq("Scope name test")
    subject.not_nil!.fields.find { |f| f.label == "Scope" }.not_nil!.value.should eq("00000000-0000-0000-0000-100000000001")
  end
end
