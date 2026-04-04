require "../../../../../spec_helper"

describe CrystalBank::Domains::Payments::Sepa::CreditTransfers::Api::CreditTransfers do
  pending_transfer_id = UUID.v7
  accepted_transfer_id = UUID.v7
  available_scope_id = UUID.new("00000000-0000-0000-0000-100000000001")

  before_all do
    projection = Payments::Sepa::CreditTransfers::Projections::CreditTransfers.new

    # Pending transfer: only Requested event applied
    req_pending = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Requested.new.create(aggr_id: pending_transfer_id)
    projection.apply(req_pending)

    # Accepted transfer: Requested then Accepted events applied
    req_accepted = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Requested.new.create(aggr_id: accepted_transfer_id)
    acc_accepted = Test::Payments::Sepa::CreditTransfers::Events::Initiation::Accepted.new.create(aggr_id: accepted_transfer_id)
    projection.apply(req_accepted)
    projection.apply(acc_accepted)
  end

  describe "GET /payments/sepa/credit-transfers - scope filtering" do
    it "returns seeded transfers when available_scopes matches" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_payments_sepa_credit_transfers_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Payments::Sepa::CreditTransfers::Queries::CreditTransfers.new.list(context, cursor: nil, limit: 100)
      uuids = results.map(&.uuid)
      uuids.should contain(pending_transfer_id)
      uuids.should contain(accepted_transfer_id)
    end

    it "returns no transfers when available_scopes does not match" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_payments_sepa_credit_transfers_list,
        scope: UUID.v7,
        available_scopes: [UUID.v7]
      )

      results = Payments::Sepa::CreditTransfers::Queries::CreditTransfers.new.list(context, cursor: nil, limit: 100)
      uuids = results.map(&.uuid)
      uuids.should_not contain(pending_transfer_id)
      uuids.should_not contain(accepted_transfer_id)
    end

    it "returns no transfers when cursor is past all records" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_payments_sepa_credit_transfers_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Payments::Sepa::CreditTransfers::Queries::CreditTransfers.new.list(context, cursor: UUID.new("ffffffff-ffff-ffff-ffff-ffffffffffff"), limit: 100)
      results.should be_empty
    end

    it "returns only pending transfers when status = pending" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_payments_sepa_credit_transfers_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Payments::Sepa::CreditTransfers::Queries::CreditTransfers.new.list(context, cursor: nil, limit: 100, status: "pending_approval")
      uuids = results.map(&.uuid)
      uuids.should contain(pending_transfer_id)
      uuids.should_not contain(accepted_transfer_id)
    end

    it "returns only accepted transfers when status = accepted" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_payments_sepa_credit_transfers_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Payments::Sepa::CreditTransfers::Queries::CreditTransfers.new.list(context, cursor: nil, limit: 100, status: "accepted")
      uuids = results.map(&.uuid)
      uuids.should contain(accepted_transfer_id)
      uuids.should_not contain(pending_transfer_id)
    end
  end
end
