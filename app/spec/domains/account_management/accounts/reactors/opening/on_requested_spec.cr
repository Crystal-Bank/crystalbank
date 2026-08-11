require "../../../../../spec_helper"

private def find_approval_id_for(source_aggregate_id : UUID) : UUID?
  found = nil
  TEST_EVENT_STORE.each_event do |raw|
    next unless raw.header["event_handle"]?.try(&.as_s) == "approval.creation.requested"
    next unless raw.body["source_aggregate_id"]?.try(&.as_s) == source_aggregate_id.to_s
    found = UUID.new(raw.header["aggregate_id"].as_s)
  end
  found
end

describe CrystalBank::Domains::Accounts::Reactors::Opening::OnRequested do
  it "creates an approval with a subject snapshot containing name, type, and currencies" do
    account_id = UUID.v7

    event = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(event)

    Accounts::Reactors::Opening::OnRequested.new.call(event)

    approval_id = find_approval_id_for(account_id)
    approval_id.should_not be_nil
    apply_projection(approval_id.not_nil!)

    approval = Approvals::Queries::Approvals.new.find_by_source("Account", account_id)
    approval.should_not be_nil
    approval.not_nil!.required_approvals.should contain("write_accounts_opening_compliance_approval")

    subject = approval.not_nil!.subject
    subject.should_not be_nil
    subject.not_nil!.title.should eq("Account Opening")
    subject.not_nil!.summary.should contain("Test Account")
    subject.not_nil!.summary.should contain("checking")
    field_labels = subject.not_nil!.fields.map(&.label)
    field_labels.should contain("Name")
    field_labels.should contain("Type")
    field_labels.should contain("Currencies")
    subject.not_nil!.fields.find { |f| f.label == "Name" }.not_nil!.value.should eq("Test Account")
    subject.not_nil!.fields.find { |f| f.label == "Type" }.not_nil!.value.should eq("checking")
    currencies_value = subject.not_nil!.fields.find { |f| f.label == "Currencies" }.not_nil!.value
    currencies_value.should contain("eur")
    currencies_value.should contain("usd")
  end
end
