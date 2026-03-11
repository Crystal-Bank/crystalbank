require "../../../../spec_helper"

# POST /ledger/transactions
# The endpoint calls `Ledger::Transactions::Request::Commands::Request#call` with
# a `TransactionRequest` body and a `CrystalBank::Api::Context` that includes
# the actor's user_id and scope. These integration tests exercise that full
# command path, verifying the contract the API controller enforces.
describe CrystalBank::Domains::Ledger::Transactions::Api::Transactions do
  describe "POST /ledger/transactions - requires valid scope and open accounts" do
    it "stores a Requested event and returns a transaction id when scope is valid and accounts are open" do
      scope_id = UUID.v7
      user_id = UUID.v7
      debit_account_id = UUID.v7
      credit_account_id = UUID.v7

      # Open two accounts so the command can validate them
      debit_requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: debit_account_id)
      debit_accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: debit_account_id)
      credit_requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: credit_account_id)
      credit_accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: credit_account_id)

      TEST_EVENT_STORE.append(debit_requested)
      TEST_EVENT_STORE.append(debit_accepted)
      TEST_EVENT_STORE.append(credit_requested)
      TEST_EVENT_STORE.append(credit_accepted)

      Accounts::Projections::Accounts.new.apply(debit_accepted)
      Accounts::Projections::Accounts.new.apply(credit_accepted)

      # Build a context as the API controller would after a successful authorized? call
      context = CrystalBank::Api::Context.new(
        user_id: user_id,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::WRITE_ledger_transactions_request,
        scope: scope_id,
        available_scopes: [scope_id]
      )

      json = {
        "currency"               => "eur",
        "remittance_information" => "Invoice INV-2024-001",
        "posting_date"           => "2026-03-11",
        "value_date"             => "2026-03-12",
        "entries"                => [
          {"account_id" => debit_account_id.to_s, "direction" => "DEBIT", "amount" => 10000, "entry_type" => "PRINCIPAL"},
          {"account_id" => credit_account_id.to_s, "direction" => "CREDIT", "amount" => 10000, "entry_type" => "PRINCIPAL"},
        ],
      }.to_json

      request = Ledger::Transactions::Api::Requests::TransactionRequest.from_json(json)
      transaction_id = Ledger::Transactions::Request::Commands::Request.new.call(request, context)

      transaction_id.should be_a(UUID)

      # Verify the Requested event was persisted for the returned id
      aggregate = Ledger::Transactions::Aggregate.new(transaction_id)
      aggregate.hydrate

      aggregate.state.currency.should eq(CrystalBank::Types::Currencies::Supported::EUR)
      aggregate.state.remittance_information.should eq("Invoice INV-2024-001")
      aggregate.state.scope_id.should eq(scope_id)
      aggregate.state.entries.not_nil!.size.should eq(2)
    end

    it "rejects the request when a referenced account is not open" do
      scope_id = UUID.v7
      user_id = UUID.v7
      debit_account_id = UUID.v7  # not in the projection
      credit_account_id = UUID.v7 # not in the projection

      context = CrystalBank::Api::Context.new(
        user_id: user_id,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::WRITE_ledger_transactions_request,
        scope: scope_id,
        available_scopes: [scope_id]
      )

      json = {
        "currency"               => "eur",
        "remittance_information" => "Invalid transfer",
        "posting_date"           => "2026-03-11",
        "value_date"             => "2026-03-12",
        "entries"                => [
          {"account_id" => debit_account_id.to_s, "direction" => "DEBIT", "amount" => 500, "entry_type" => "PRINCIPAL"},
          {"account_id" => credit_account_id.to_s, "direction" => "CREDIT", "amount" => 500, "entry_type" => "PRINCIPAL"},
        ],
      }.to_json

      request = Ledger::Transactions::Api::Requests::TransactionRequest.from_json(json)

      expect_raises(CrystalBank::Exception::InvalidArgument, /not open/) do
        Ledger::Transactions::Request::Commands::Request.new.call(request, context)
      end
    end
  end
end
