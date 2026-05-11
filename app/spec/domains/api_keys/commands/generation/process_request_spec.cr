require "../../../../spec_helper"

describe CrystalBank::Domains::ApiKeys::Generation::Commands::ProcessRequest do
  it "creates an approval with a subject snapshot containing name, user, and key ID" do
    api_key_id = UUID.v7
    expected_user_id = UUID.new("00000000-0000-0000-0000-000000000000")

    event = Test::ApiKey::Events::Generation::Requested.new.create(aggr_id: api_key_id)
    TEST_EVENT_STORE.append(event)

    approval_id = ApiKeys::Generation::Commands::ProcessRequest.new(aggregate_id: api_key_id).call
    apply_projection(approval_id)

    approval = Approvals::Queries::Approvals.new.find_by_source("ApiKey", api_key_id)
    approval.should_not be_nil
    approval.not_nil!.required_approvals.should contain("write_api_keys_generation_approval")

    subject = approval.not_nil!.subject
    subject.should_not be_nil
    subject.not_nil!.title.should eq("API Key Generation")
    subject.not_nil!.summary.should eq("test name")
    field_labels = subject.not_nil!.fields.map(&.label)
    field_labels.should contain("Name")
    field_labels.should contain("User")
    field_labels.should contain("Key ID")
    subject.not_nil!.fields.find { |f| f.label == "Name" }.not_nil!.value.should eq("test name")
    subject.not_nil!.fields.find { |f| f.label == "User" }.not_nil!.value.should eq(expected_user_id.to_s)
    subject.not_nil!.fields.find { |f| f.label == "Key ID" }.not_nil!.value.should eq(api_key_id.to_s)
  end
end
