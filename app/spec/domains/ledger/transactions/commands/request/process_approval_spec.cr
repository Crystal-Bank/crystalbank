require "../../../../../spec_helper"

describe CrystalBank::Domains::Ledger::Transactions::Request::Commands::ProcessApproval do
  it "accepts the ledger transaction after the approval is completed" do
    tx_id = UUID.v7
    scope_id = UUID.v7

    requested = Test::Ledger::Transactions::Events::Request::Requested.new.create(aggr_id: tx_id)
    TEST_EVENT_STORE.append(requested)

    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "LedgerTransaction",
      source_aggregate_id: tx_id,
      scope_id: scope_id,
      required_approvals: ["write_ledger_transactions_request_approval"],
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

    transaction = Ledger::Transactions::Aggregate.new(tx_id)
    transaction.hydrate

    transaction.state.status.should eq("accepted")
  end

  it "ignores a completed approval with a different source aggregate type" do
    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "SomeUnhandledType",
      source_aggregate_id: UUID.v7,
      scope_id: UUID.v7,
      required_approvals: ["write_ledger_transactions_request_approval"],
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

  it "creates postings in the projection after approval" do
    tx_id = UUID.v7

    requested = Test::Ledger::Transactions::Events::Request::Requested.new.create(aggr_id: tx_id)
    TEST_EVENT_STORE.append(requested)

    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "LedgerTransaction",
      source_aggregate_id: tx_id,
      scope_id: UUID.new("00000000-0000-0000-0000-100000000001"), # matches factory scope_id
      required_approvals: ["write_ledger_transactions_request_approval"],
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

    # Replay approval events — this triggers ProcessApproval which appends Accepted to the store
    apply_projection(approval_id)
    # Replay ledger transaction events — this publishes Accepted and triggers the Postings projection
    apply_projection(tx_id)

    count = TEST_PROJECTION_DB.scalar(
      %(SELECT count(*) FROM "projections"."postings" WHERE transaction_id = $1),
      tx_id
    )
    count.should eq(2)
  end
end
