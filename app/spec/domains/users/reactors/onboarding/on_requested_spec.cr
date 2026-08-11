require "../../../../spec_helper"

describe CrystalBank::Domains::Users::Reactors::Onboarding::OnRequested do
  it "does not mark the user as onboarded before approval" do
    user_id = UUID.v7

    event = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    TEST_EVENT_STORE.append(event)

    Users::Reactors::Onboarding::OnRequested.new.call(event)

    aggregate = Users::Aggregate.new(user_id)
    aggregate.hydrate

    aggregate.state.onboarded.should be_false
  end

  it "creates an approval with a subject snapshot containing name and email" do
    user_id = UUID.v7

    event = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    TEST_EVENT_STORE.append(event)

    Users::Reactors::Onboarding::OnRequested.new.call(event)

    found = nil
    TEST_EVENT_STORE.each_event do |raw|
      next unless raw.header["event_handle"]?.try(&.as_s) == "approval.creation.requested"
      next unless raw.body["source_aggregate_id"]?.try(&.as_s) == user_id.to_s
      found = UUID.new(raw.header["aggregate_id"].as_s)
    end
    found.should_not be_nil
    apply_projection(found.not_nil!)

    approval = Approvals::Queries::Approvals.new.find_by_source("User", user_id)
    approval.should_not be_nil

    subject = approval.not_nil!.subject
    subject.should_not be_nil
    subject.not_nil!.title.should eq("User Onboarding")
    subject.not_nil!.summary.should contain("Peter Pan")
    subject.not_nil!.summary.should contain("test@crystalbank.xyz")
    field_labels = subject.not_nil!.fields.map(&.label)
    field_labels.should contain("Name")
    field_labels.should contain("Email")
    subject.not_nil!.fields.find { |f| f.label == "Name" }.not_nil!.value.should eq("Peter Pan")
    subject.not_nil!.fields.find { |f| f.label == "Email" }.not_nil!.value.should eq("test@crystalbank.xyz")
  end
end
