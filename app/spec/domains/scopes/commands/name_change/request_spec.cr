require "../../../../spec_helper"

private def seed_active_scope_for_rename(scope_id : UUID)
  req = Test::Scope::Events::Creation::Requested.new.create(aggr_id: scope_id)
  acc = Test::Scope::Events::Creation::Accepted.new.create(aggr_id: scope_id)
  TEST_EVENT_STORE.append(req)
  TEST_EVENT_STORE.append(acc)
  Scopes::Projections::Scopes.new.apply(req)
  Scopes::Projections::Scopes.new.apply(acc)
end

describe CrystalBank::Domains::Scopes::NameChange::Commands::Request do
  it "creates an approval with a subject snapshot containing old and new name" do
    scope_id = UUID.v7
    seed_active_scope_for_rename(scope_id)

    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_scopes_name_change_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    request = Scopes::Api::Requests::NameChangeRequest.from_json(
      {scope_id: scope_id.to_s, name: "New Scope Name"}.to_json
    )
    result = Scopes::NameChange::Commands::Request.new.call(request, context)

    apply_projection(result[:approval_id])

    approval = Approvals::Queries::Approvals.new.find_by_source("ScopeNameChange", result[:name_change_request_id])
    approval.should_not be_nil
    approval.not_nil!.required_approvals.should contain("write_scopes_name_change_approval")

    subject = approval.not_nil!.subject
    subject.should_not be_nil
    subject.not_nil!.title.should eq("Scope Rename")
    subject.not_nil!.summary.should contain("Scope name test")
    subject.not_nil!.summary.should contain("New Scope Name")
    field_labels = subject.not_nil!.fields.map(&.label)
    field_labels.should contain("From")
    field_labels.should contain("To")
    subject.not_nil!.fields.find { |f| f.label == "From" }.not_nil!.value.should eq("Scope name test")
    subject.not_nil!.fields.find { |f| f.label == "To" }.not_nil!.value.should eq("New Scope Name")
  end

  it "raises when scope is missing from context" do
    scope_id = UUID.v7
    seed_active_scope_for_rename(scope_id)

    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_scopes_name_change_request,
      scope: nil,
      available_scopes: [] of UUID
    )

    request = Scopes::Api::Requests::NameChangeRequest.from_json(
      {scope_id: scope_id.to_s, name: "New Scope Name"}.to_json
    )

    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid scope/) do
      Scopes::NameChange::Commands::Request.new.call(request, context)
    end
  end
end
