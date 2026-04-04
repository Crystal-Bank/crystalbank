require "../../../../../spec_helper"

module TestEnv
  class_property debit_account_id : UUID = UUID.random
  class_property credit_account_id : UUID = UUID.random
end

describe CrystalBank::Domains::Ledger::Transactions::Request::Commands::Request do
  before_all do
    # This runs once before all tests in this describe block
    debit_account_id = UUID.v7
    credit_account_id = UUID.v7

    # Set up open accounts via event sourcing + projection
    debit_requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: debit_account_id)
    debit_accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: debit_account_id)
    credit_requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: credit_account_id)
    credit_accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: credit_account_id)

    TEST_EVENT_STORE.append(debit_requested)
    TEST_EVENT_STORE.append(debit_accepted)
    TEST_EVENT_STORE.append(credit_requested)
    TEST_EVENT_STORE.append(credit_accepted)

    accounts_projection = Accounts::Projections::Accounts.new
    accounts_projection.apply(debit_requested)
    accounts_projection.apply(debit_accepted)
    accounts_projection.apply(credit_requested)
    accounts_projection.apply(credit_accepted)

    TestEnv.debit_account_id = debit_account_id
    TestEnv.credit_account_id = credit_account_id
  end

  it "creates a transaction when accounts are open and scope is valid" do
    scope_id = UUID.v7
    user_id = UUID.v7
    debit_account_id = UUID.v7
    credit_account_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id: user_id,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_ledger_transactions_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    json = {
      "currency"               => "EUR",
      "remittance_information" => "Payment ref 001",
      "posting_date"           => "2026-03-11",
      "value_date"             => "2026-03-12",
      "entries"                => [
        {"account_id" => TestEnv.debit_account_id.to_s, "direction" => "debit", "amount" => 5000, "entry_type" => "PRINCIPAL"},
        {"account_id" => TestEnv.credit_account_id.to_s, "direction" => "credit", "amount" => 5000, "entry_type" => "PRINCIPAL"},
      ],
    }.to_json

    request = Ledger::Transactions::Api::Requests::TransactionRequest.from_json(json)

    result = Ledger::Transactions::Request::Commands::Request.new.call(request, context)
    result.should be_a(UUID)
  end

  it "raises when an account is not open" do
    scope_id = UUID.v7
    user_id = UUID.v7
    debit_account_id = UUID.v7
    credit_account_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id: user_id,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_ledger_transactions_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    json = {
      "currency"               => "EUR",
      "remittance_information" => "Payment ref 002",
      "posting_date"           => "2026-03-11",
      "value_date"             => "2026-03-12",
      "entries"                => [
        {"account_id" => debit_account_id.to_s, "direction" => "debit", "amount" => 1000, "entry_type" => "PRINCIPAL"},
        {"account_id" => credit_account_id.to_s, "direction" => "credit", "amount" => 1000, "entry_type" => "PRINCIPAL"},
      ],
    }.to_json

    request = Ledger::Transactions::Api::Requests::TransactionRequest.from_json(json)

    expect_raises(CrystalBank::Exception::InvalidArgument, /not open/) do
      Ledger::Transactions::Request::Commands::Request.new.call(request, context)
    end
  end

  it "raises when an account does not support the transfer currency" do
    scope_id = UUID.v7
    user_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id: user_id,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_ledger_transactions_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    # Accounts in TestEnv support EUR and USD only; GBP is not in their supported currencies
    json = {
      "currency"               => "GBP",
      "remittance_information" => "Payment ref 005",
      "posting_date"           => "2026-03-11",
      "value_date"             => "2026-03-12",
      "entries"                => [
        {"account_id" => TestEnv.debit_account_id.to_s, "direction" => "debit", "amount" => 2000, "entry_type" => "PRINCIPAL"},
        {"account_id" => TestEnv.credit_account_id.to_s, "direction" => "credit", "amount" => 2000, "entry_type" => "PRINCIPAL"},
      ],
    }.to_json

    request = Ledger::Transactions::Api::Requests::TransactionRequest.from_json(json)

    expect_raises(CrystalBank::Exception::InvalidArgument, /does not support currency/) do
      Ledger::Transactions::Request::Commands::Request.new.call(request, context)
    end
  end

  it "raises when entries do not balance" do
    scope_id = UUID.new("00000000-0000-0000-0000-000000000000")
    user_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id: user_id,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_ledger_transactions_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    json = {
      "currency"               => "EUR",
      "remittance_information" => "Payment ref 003",
      "posting_date"           => "2026-03-11",
      "value_date"             => "2026-03-12",
      "entries"                => [
        {"account_id" => TestEnv.debit_account_id.to_s, "direction" => "DEBIT", "amount" => 5000, "entry_type" => "PRINCIPAL"},
        {"account_id" => TestEnv.credit_account_id.to_s, "direction" => "CREDIT", "amount" => 3000, "entry_type" => "PRINCIPAL"},
      ],
    }.to_json

    request = Ledger::Transactions::Api::Requests::TransactionRequest.from_json(json)

    expect_raises(CrystalBank::Exception::InvalidArgument, /do not balance/) do
      Ledger::Transactions::Request::Commands::Request.new.call(request, context)
    end
  end

  it "raises when fewer than two entries are provided" do
    scope_id = UUID.new("00000000-0000-0000-0000-000000000000")
    user_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id: user_id,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_ledger_transactions_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    json = {
      "currency"               => "EUR",
      "remittance_information" => "Payment ref 004",
      "posting_date"           => "2026-03-11",
      "value_date"             => "2026-03-12",
      "entries"                => [
        {"account_id" => TestEnv.debit_account_id.to_s, "direction" => "debit", "amount" => 1000, "entry_type" => "PRINCIPAL"},
      ],
    }.to_json

    request = Ledger::Transactions::Api::Requests::TransactionRequest.from_json(json)

    expect_raises(CrystalBank::Exception::InvalidArgument, /At least two entries/) do
      Ledger::Transactions::Request::Commands::Request.new.call(request, context)
    end
  end
end
