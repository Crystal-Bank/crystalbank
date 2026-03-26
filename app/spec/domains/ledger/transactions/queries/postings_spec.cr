require "../../../../spec_helper"

# Builds a Requested event with custom debit/credit account IDs and scope.
private def build_posting_requested(aggr_id : UUID, scope_id : UUID, debit_account_id : UUID, credit_account_id : UUID)
  entries = [
    ::Ledger::Transactions::Aggregate::Entry.new(
      id: UUID.v7,
      account_id: debit_account_id,
      direction: "debit",
      amount: 10000_i64,
      entry_type: "PRINCIPAL",
    ),
    ::Ledger::Transactions::Aggregate::Entry.new(
      id: UUID.v7,
      account_id: credit_account_id,
      direction: "credit",
      amount: 10000_i64,
      entry_type: "PRINCIPAL",
    ),
  ]

  ::Ledger::Transactions::Request::Events::Requested.new(
    actor_id: UUID.v7,
    aggregate_id: aggr_id,
    currency: CrystalBank::Types::Currencies::Supported::EUR,
    entries_json: entries.to_json,
    posting_date: Time::Format::ISO_8601_DATE.parse("2026-03-11"),
    value_date: Time::Format::ISO_8601_DATE.parse("2026-03-12"),
    remittance_information: "test",
    payment_type: nil,
    external_ref: nil,
    channel: "api",
    scope_id: scope_id,
    command_handler: "test",
    comment: "test",
  )
end

describe CrystalBank::Domains::Ledger::Transactions::Queries::Postings do
  describe "account_id filter" do
    it "returns only postings for the given account_id" do
      scope_id = UUID.v7
      alpha_id = UUID.v7  # shared across both transactions
      beta_id  = UUID.v7  # only in transaction 1
      gamma_id = UUID.v7  # only in transaction 2
      tx1_id   = UUID.v7
      tx2_id   = UUID.v7

      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_postings_list,
        scope: scope_id,
        available_scopes: [scope_id]
      )

      # Transaction 1: alpha (debit) ↔ beta (credit)
      req1 = build_posting_requested(tx1_id, scope_id, alpha_id, beta_id)
      acc1 = Test::Ledger::Transactions::Events::Request::Accepted.new.create(aggr_id: tx1_id)
      TEST_EVENT_STORE.append(req1)
      TEST_EVENT_STORE.append(acc1)
      Ledger::Transactions::Projections::Postings.new.apply(acc1)

      # Transaction 2: alpha (debit) ↔ gamma (credit)
      req2 = build_posting_requested(tx2_id, scope_id, alpha_id, gamma_id)
      acc2 = Test::Ledger::Transactions::Events::Request::Accepted.new.create(aggr_id: tx2_id)
      TEST_EVENT_STORE.append(req2)
      TEST_EVENT_STORE.append(acc2)
      Ledger::Transactions::Projections::Postings.new.apply(acc2)

      # alpha appears in both transactions → 2 postings
      alpha_results = Ledger::Transactions::Queries::Postings.new.list(context, cursor: nil, limit: 10, account_id: alpha_id)
      alpha_results.size.should eq(2)
      alpha_results.all? { |p| p.account_id == alpha_id }.should be_true

      # gamma appears only in transaction 2 → 1 posting
      gamma_results = Ledger::Transactions::Queries::Postings.new.list(context, cursor: nil, limit: 10, account_id: gamma_id)
      gamma_results.size.should eq(1)
      gamma_results.first.account_id.should eq(gamma_id)

      # no filter → all 4 postings within the scope
      all_results = Ledger::Transactions::Queries::Postings.new.list(context, cursor: nil, limit: 10, account_id: nil)
      all_results.size.should eq(4)
    end

    it "returns an empty list when the account_id has no postings in scope" do
      scope_id    = UUID.v7
      unknown_id  = UUID.v7

      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_postings_list,
        scope: scope_id,
        available_scopes: [scope_id]
      )

      results = Ledger::Transactions::Queries::Postings.new.list(context, cursor: nil, limit: 10, account_id: unknown_id)
      results.should be_empty
    end
  end
end
