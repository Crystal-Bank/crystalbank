require "../../../../spec_helper"

describe CrystalBank::Domains::ApiKeys::Generation::Commands::ProcessApproval do
  it "activates the api key after the approval is completed" do
    api_key_id = UUID.v7

    requested = Test::ApiKey::Events::Generation::Requested.new.create(aggr_id: api_key_id)
    TEST_EVENT_STORE.append(requested)

    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "ApiKey",
      source_aggregate_id: api_key_id,
      scope_id: UUID.new("00000000-0000-0000-0000-000000000001"),
      required_approvals: ["write_api_keys_generation_approval"],
      actor_id: UUID.v7,
    )

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    apply_projection(approval_id)

    api_key = ApiKeys::Aggregate.new(api_key_id)
    api_key.hydrate

    api_key.state.status.should eq("active")
  end

  it "ignores a completed approval with a different source aggregate type" do
    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "SomeUnhandledType",
      source_aggregate_id: UUID.v7,
      scope_id: UUID.v7,
      required_approvals: ["write_api_keys_generation_approval"],
      actor_id: UUID.v7,
    )

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    apply_projection(approval_id)
  end
end
