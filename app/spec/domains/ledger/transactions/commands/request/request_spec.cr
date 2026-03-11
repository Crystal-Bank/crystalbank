require "../../../../../spec_helper"

describe CrystalBank::Domains::Ledger::Transactions::Request::Commands::Request do
  it "creates a transaction when accounts are open and scope is valid" do
    scope_id = UUID.v7
    user_id = UUID.v7
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
    accounts_projection.apply(debit_accepted)
    accounts_projection.apply(credit_accepted)

    context = CrystalBank::Api::Context.new(
      user_id,
      [] of UUID,
      CrystalBank::Permissions::WRITE_ledger_transactions_request,
      scope_id,
      [scope_id]
    )

    json = {
      "currency"               => "EUR",
      "remittance_information" => "Payment ref 001",
      "entries"                => [
        {"account_id" => debit_account_id.to_s, "direction" => "DEBIT", "amount" => 5000, "entry_type" => "PRINCIPAL"},
        {"account_id" => credit_account_id.to_s, "direction" => "CREDIT", "amount" => 5000, "entry_type" => "PRINCIPAL"},
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
      user_id,
      [] of UUID,
      CrystalBank::Permissions::WRITE_ledger_transactions_request,
      scope_id,
      [scope_id]
    )

    json = {
      "currency"               => "EUR",
      "remittance_information" => "Payment ref 002",
      "entries"                => [
        {"account_id" => debit_account_id.to_s, "direction" => "DEBIT", "amount" => 1000, "entry_type" => "PRINCIPAL"},
        {"account_id" => credit_account_id.to_s, "direction" => "CREDIT", "amount" => 1000, "entry_type" => "PRINCIPAL"},
      ],
    }.to_json

    request = Ledger::Transactions::Api::Requests::TransactionRequest.from_json(json)

    expect_raises(CrystalBank::Exception::InvalidArgument, /not open/) do
      Ledger::Transactions::Request::Commands::Request.new.call(request, context)
    end
  end

  it "raises when entries do not balance" do
    scope_id = UUID.v7
    user_id = UUID.v7
    debit_account_id = UUID.v7
    credit_account_id = UUID.v7

    debit_requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: debit_account_id)
    debit_accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: debit_account_id)
    credit_requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: credit_account_id)
    credit_accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: credit_account_id)

    TEST_EVENT_STORE.append(debit_requested)
    TEST_EVENT_STORE.append(debit_accepted)
    TEST_EVENT_STORE.append(credit_requested)
    TEST_EVENT_STORE.append(credit_accepted)

    accounts_projection = Accounts::Projections::Accounts.new
    accounts_projection.apply(debit_accepted)
    accounts_projection.apply(credit_accepted)

    context = CrystalBank::Api::Context.new(
      user_id,
      [] of UUID,
      CrystalBank::Permissions::WRITE_ledger_transactions_request,
      scope_id,
      [scope_id]
    )

    json = {
      "currency"               => "EUR",
      "remittance_information" => "Payment ref 003",
      "entries"                => [
        {"account_id" => debit_account_id.to_s, "direction" => "DEBIT", "amount" => 5000, "entry_type" => "PRINCIPAL"},
        {"account_id" => credit_account_id.to_s, "direction" => "CREDIT", "amount" => 3000, "entry_type" => "PRINCIPAL"},
      ],
    }.to_json

    request = Ledger::Transactions::Api::Requests::TransactionRequest.from_json(json)

    expect_raises(CrystalBank::Exception::InvalidArgument, /do not balance/) do
      Ledger::Transactions::Request::Commands::Request.new.call(request, context)
    end
  end

  it "raises when fewer than two entries are provided" do
    scope_id = UUID.v7
    user_id = UUID.v7
    debit_account_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id,
      [] of UUID,
      CrystalBank::Permissions::WRITE_ledger_transactions_request,
      scope_id,
      [scope_id]
    )

    json = {
      "currency"               => "EUR",
      "remittance_information" => "Payment ref 004",
      "entries"                => [
        {"account_id" => debit_account_id.to_s, "direction" => "DEBIT", "amount" => 1000, "entry_type" => "PRINCIPAL"},
      ],
    }.to_json

    request = Ledger::Transactions::Api::Requests::TransactionRequest.from_json(json)

    expect_raises(CrystalBank::Exception::InvalidArgument, /At least two entries/) do
      Ledger::Transactions::Request::Commands::Request.new.call(request, context)
    end
  end

  it "raises when scope is missing from context" do
    user_id = UUID.v7
    debit_account_id = UUID.v7
    credit_account_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id,
      [] of UUID,
      CrystalBank::Permissions::WRITE_ledger_transactions_request,
      nil,
      [] of UUID
    )

    json = {
      "currency"               => "EUR",
      "remittance_information" => "Payment ref 005",
      "entries"                => [
        {"account_id" => debit_account_id.to_s, "direction" => "DEBIT", "amount" => 1000, "entry_type" => "PRINCIPAL"},
        {"account_id" => credit_account_id.to_s, "direction" => "CREDIT", "amount" => 1000, "entry_type" => "PRINCIPAL"},
      ],
    }.to_json

    request = Ledger::Transactions::Api::Requests::TransactionRequest.from_json(json)

    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid scope/) do
      Ledger::Transactions::Request::Commands::Request.new.call(request, context)
    end
  end
end
