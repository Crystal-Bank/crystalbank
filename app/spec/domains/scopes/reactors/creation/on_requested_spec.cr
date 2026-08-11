require "../../../../spec_helper"

describe CrystalBank::Domains::Scopes::Reactors::Creation::OnRequested do
  it "creates an approval with a subject snapshot containing name and parent scope" do
    scope_id = UUID.v7

    event = Test::Scope::Events::Creation::Requested.new.create(aggr_id: scope_id)
    TEST_EVENT_STORE.append(event)

    Scopes::Reactors::Creation::OnRequested.new.call(event)

    found = nil
    TEST_EVENT_STORE.each_event do |raw|
      next unless raw.header["event_handle"]?.try(&.as_s) == "approval.creation.requested"
      next unless raw.body["source_aggregate_id"]?.try(&.as_s) == scope_id.to_s
      found = UUID.new(raw.header["aggregate_id"].as_s)
    end
    found.should_not be_nil
    apply_projection(found.not_nil!)

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
