require "../../../../spec_helper"

describe CrystalBank::Domains::Scopes::Creation::Commands::ProcessRequest do
  it "creates an approval with a subject snapshot containing name and parent scope" do
    scope_id = UUID.v7

    event = Test::Scope::Events::Creation::Requested.new.create(aggr_id: scope_id)
    TEST_EVENT_STORE.append(event)

    approval_id = Scopes::Creation::Commands::ProcessRequest.new(aggregate_id: scope_id).call
    apply_projection(approval_id)

    approval = Approvals::Queries::Approvals.new.find_by_source("Scope", scope_id)
    approval.should_not be_nil
    approval.not_nil!.required_approvals.should contain("write_scopes_creation_approval")

    subject = approval.not_nil!.subject
    subject.should_not be_nil
    subject.not_nil!.title.should eq("Scope Creation")
    subject.not_nil!.summary.should eq("Scope name test")
    field_labels = subject.not_nil!.fields.map(&.label)
    field_labels.should contain("Name")
    field_labels.should contain("Parent Scope")
    subject.not_nil!.fields.find { |f| f.label == "Name" }.not_nil!.value.should eq("Scope name test")
    parent_field = subject.not_nil!.fields.find { |f| f.label == "Parent Scope" }.not_nil!.value
    parent_field.should contain("00000000-0000-0000-0000-200000000001")
  end
end
