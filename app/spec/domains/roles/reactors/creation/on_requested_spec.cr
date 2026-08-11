require "../../../../spec_helper"

describe CrystalBank::Domains::Roles::Reactors::Creation::OnRequested do
  it "does not accept the role before approval" do
    role_id = UUID.v7

    event = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
    TEST_EVENT_STORE.append(event)

    Roles::Reactors::Creation::OnRequested.new.call(event)

    aggregate = Roles::Aggregate.new(role_id)
    aggregate.hydrate

    aggregate.state.aggregate_version.should eq(1)
  end

  it "creates an approval with a subject snapshot containing name and scope" do
    role_id = UUID.v7
    scope_id = UUID.new("00000000-0000-0000-0000-100000000001")

    scope_req = Test::Scope::Events::Creation::Requested.new.create(aggr_id: scope_id)
    scope_acc = Test::Scope::Events::Creation::Accepted.new.create(aggr_id: scope_id)
    TEST_EVENT_STORE.append(scope_req)
    TEST_EVENT_STORE.append(scope_acc)
    Scopes::Projections::Scopes.new.apply(scope_req)
    Scopes::Projections::Scopes.new.apply(scope_acc)

    event = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
    TEST_EVENT_STORE.append(event)

    Roles::Reactors::Creation::OnRequested.new.call(event)

    found = nil
    TEST_EVENT_STORE.each_event do |raw|
      next unless raw.header["event_handle"]?.try(&.as_s) == "approval.creation.requested"
      next unless raw.body["source_aggregate_id"]?.try(&.as_s) == role_id.to_s
      found = UUID.new(raw.header["aggregate_id"].as_s)
    end
    found.should_not be_nil
    apply_projection(found.not_nil!)

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
    subject.not_nil!.fields.find { |f| f.label == "Scope" }.not_nil!.value.should eq("Scope name test (#{scope_id})")
  end
end
