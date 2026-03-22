require "../../../../../spec_helper"

describe CrystalBank::Domains::Payments::Sepa::CreditTransfers::Queries::CreditTransfers do
  # Fixed scope so seeded rows are visible across tests in this block
  available_scope_id = UUID.new("00000000-0000-0000-0000-100000000001")

  pending_id = UUID.v7
  accepted_id = UUID.v7

  before_all do
    projection = Payments::Sepa::CreditTransfers::Projections::CreditTransfers.new

    requested_pending = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Requested.new.create(aggr_id: pending_id)
    projection.apply(requested_pending)

    requested_accepted = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Requested.new.create(aggr_id: accepted_id)
    projection.apply(requested_accepted)

    accepted_event = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Accepted.new.create(aggr_id: accepted_id)
    projection.apply(accepted_event)
  end

  it "lists all transfers visible to the caller's scope" do
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::READ_payments_sepa_credit_transfers_list,
      scope: UUID.v7,
      available_scopes: [available_scope_id]
    )

    results = Payments::Sepa::CreditTransfers::Queries::CreditTransfers.new.list(context, cursor: nil, limit: 100)
    ids = results.map(&.uuid)

    ids.should contain(pending_id)
    ids.should contain(accepted_id)
  end

  it "filters by status=pending" do
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::READ_payments_sepa_credit_transfers_list,
      scope: UUID.v7,
      available_scopes: [available_scope_id]
    )

    results = Payments::Sepa::CreditTransfers::Queries::CreditTransfers.new.list(context, cursor: nil, limit: 100, status: "pending")
    ids = results.map(&.uuid)

    ids.should contain(pending_id)
    ids.should_not contain(accepted_id)
  end

  it "filters by status=accepted" do
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::READ_payments_sepa_credit_transfers_list,
      scope: UUID.v7,
      available_scopes: [available_scope_id]
    )

    results = Payments::Sepa::CreditTransfers::Queries::CreditTransfers.new.list(context, cursor: nil, limit: 100, status: "accepted")
    ids = results.map(&.uuid)

    ids.should contain(accepted_id)
    ids.should_not contain(pending_id)
  end

  it "returns nothing for a scope the caller cannot access" do
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::READ_payments_sepa_credit_transfers_list,
      scope: UUID.v7,
      available_scopes: [UUID.v7]
    )

    results = Payments::Sepa::CreditTransfers::Queries::CreditTransfers.new.list(context, cursor: nil, limit: 100)
    ids = results.map(&.uuid)

    ids.should_not contain(pending_id)
    ids.should_not contain(accepted_id)
  end

  it "respects the limit parameter" do
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::READ_payments_sepa_credit_transfers_list,
      scope: UUID.v7,
      available_scopes: [available_scope_id]
    )

    results = Payments::Sepa::CreditTransfers::Queries::CreditTransfers.new.list(context, cursor: nil, limit: 1)
    results.size.should eq(1)
  end
end
