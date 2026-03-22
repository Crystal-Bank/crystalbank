require "../../../../../../spec_helper"

module TestEnvSepaCT
  class_property debtor_account_id : UUID = UUID.random
  class_property settlement_account_id : UUID = UUID.random
end

describe CrystalBank::Domains::Payments::Sepa::CreditTransfers::Initiation::Commands::Request do
  before_all do
    debtor_account_id = UUID.v7
    settlement_account_id = UUID.v7

    # Open two EUR-enabled accounts that the command can validate against
    [debtor_account_id, settlement_account_id].each do |account_id|
      requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
      accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
      TEST_EVENT_STORE.append(requested)
      TEST_EVENT_STORE.append(accepted)
      Accounts::Projections::Accounts.new.apply(accepted)
    end

    TestEnvSepaCT.debtor_account_id = debtor_account_id
    TestEnvSepaCT.settlement_account_id = settlement_account_id

    # Configure the settlement account via ENV (as it would be in production)
    ENV["SEPA_SETTLEMENT_ACCOUNT_ID"] = settlement_account_id.to_s
  end

  it "creates a SEPA Credit Transfer and an approval when accounts are valid" do
    scope_id = UUID.v7
    user_id = UUID.v7

    context = CrystalBank::Api::Context.new(
      user_id: user_id,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_payments_sepa_credit_transfers_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    json = {
      "end_to_end_id"          => "E2E-SPEC-001",
      "debtor_account_id"      => TestEnvSepaCT.debtor_account_id.to_s,
      "creditor_iban"          => "DE89370400440532013000",
      "creditor_name"          => "Acme GmbH",
      "creditor_bic"           => nil,
      "amount"                 => 25000,
      "currency"               => "EUR",
      "execution_date"         => "2026-04-01",
      "remittance_information" => "Invoice #42",
    }.to_json

    request = Payments::Sepa::CreditTransfers::Api::Requests::CreditTransferRequest.from_json(json)

    result = Payments::Sepa::CreditTransfers::Initiation::Commands::Request.new.call(request, context)
    payment_id = result[:payment_id]

    payment_id.should be_a(UUID)

    # Verify aggregate state
    aggregate = Payments::Sepa::CreditTransfers::Aggregate.new(payment_id)
    aggregate.hydrate

    aggregate.state.status.should eq("pending")
    aggregate.state.end_to_end_id.should eq("E2E-SPEC-001")
    aggregate.state.amount.should eq(25000_i64)
    aggregate.state.scope_id.should eq(scope_id)

    # Apply the approval projection synchronously via the event bus, then query
    apply_projection(result[:approval_id])

    approval = Approvals::Queries::Approvals.new.find_by_source("SepaCreditTransfer", payment_id)
    approval.should_not be_nil
    approval.not_nil!.completed.should be_false
    approval.not_nil!.required_approvals.should contain("write_payments_sepa_credit_transfers_approval")
  end

  it "raises when debtor account is not open" do
    scope_id = UUID.v7
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_payments_sepa_credit_transfers_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    json = {
      "end_to_end_id"          => "E2E-SPEC-002",
      "debtor_account_id"      => UUID.v7.to_s,
      "creditor_iban"          => "DE89370400440532013000",
      "creditor_name"          => "Acme GmbH",
      "amount"                 => 1000,
      "currency"               => "EUR",
      "execution_date"         => "2026-04-01",
      "remittance_information" => "Test",
    }.to_json

    request = Payments::Sepa::CreditTransfers::Api::Requests::CreditTransferRequest.from_json(json)

    expect_raises(CrystalBank::Exception::InvalidArgument, /not open/) do
      Payments::Sepa::CreditTransfers::Initiation::Commands::Request.new.call(request, context)
    end
  end

  it "raises when settlement account (from config) is not open" do
    scope_id = UUID.v7
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_payments_sepa_credit_transfers_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    # Temporarily point the config to a non-existent account
    original = ENV["SEPA_SETTLEMENT_ACCOUNT_ID"]?
    ENV["SEPA_SETTLEMENT_ACCOUNT_ID"] = UUID.v7.to_s

    json = {
      "end_to_end_id"          => "E2E-SPEC-003",
      "debtor_account_id"      => TestEnvSepaCT.debtor_account_id.to_s,
      "creditor_iban"          => "DE89370400440532013000",
      "creditor_name"          => "Acme GmbH",
      "amount"                 => 1000,
      "currency"               => "EUR",
      "execution_date"         => "2026-04-01",
      "remittance_information" => "Test",
    }.to_json

    request = Payments::Sepa::CreditTransfers::Api::Requests::CreditTransferRequest.from_json(json)

    begin
      expect_raises(CrystalBank::Exception::InvalidArgument, /not open/) do
        Payments::Sepa::CreditTransfers::Initiation::Commands::Request.new.call(request, context)
      end
    ensure
      ENV["SEPA_SETTLEMENT_ACCOUNT_ID"] = original || TestEnvSepaCT.settlement_account_id.to_s
    end
  end

  it "raises when amount is zero or negative" do
    scope_id = UUID.v7
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_payments_sepa_credit_transfers_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    json = {
      "end_to_end_id"          => "E2E-SPEC-004",
      "debtor_account_id"      => TestEnvSepaCT.debtor_account_id.to_s,
      "creditor_iban"          => "DE89370400440532013000",
      "creditor_name"          => "Acme GmbH",
      "amount"                 => 0,
      "currency"               => "EUR",
      "execution_date"         => "2026-04-01",
      "remittance_information" => "Test",
    }.to_json

    request = Payments::Sepa::CreditTransfers::Api::Requests::CreditTransferRequest.from_json(json)

    expect_raises(CrystalBank::Exception::InvalidArgument, /Amount must be greater than zero/) do
      Payments::Sepa::CreditTransfers::Initiation::Commands::Request.new.call(request, context)
    end
  end

  it "raises when currency is not EUR" do
    scope_id = UUID.v7
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_payments_sepa_credit_transfers_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    json = {
      "end_to_end_id"          => "E2E-SPEC-005",
      "debtor_account_id"      => TestEnvSepaCT.debtor_account_id.to_s,
      "creditor_iban"          => "GB29NWBK60161331926819",
      "creditor_name"          => "Acme Ltd",
      "amount"                 => 5000,
      "currency"               => "GBP",
      "execution_date"         => "2026-04-01",
      "remittance_information" => "Test",
    }.to_json

    request = Payments::Sepa::CreditTransfers::Api::Requests::CreditTransferRequest.from_json(json)

    expect_raises(CrystalBank::Exception::InvalidArgument, /must use EUR/) do
      Payments::Sepa::CreditTransfers::Initiation::Commands::Request.new.call(request, context)
    end
  end

  it "raises when execution_date is not a valid date" do
    scope_id = UUID.v7
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_payments_sepa_credit_transfers_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    json = {
      "end_to_end_id"          => "E2E-SPEC-006",
      "debtor_account_id"      => TestEnvSepaCT.debtor_account_id.to_s,
      "creditor_iban"          => "DE89370400440532013000",
      "creditor_name"          => "Acme GmbH",
      "amount"                 => 1000,
      "currency"               => "EUR",
      "execution_date"         => "not-a-date",
      "remittance_information" => "Test",
    }.to_json

    request = Payments::Sepa::CreditTransfers::Api::Requests::CreditTransferRequest.from_json(json)

    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid execution_date/) do
      Payments::Sepa::CreditTransfers::Initiation::Commands::Request.new.call(request, context)
    end
  end

  it "raises when scope is missing from context" do
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_payments_sepa_credit_transfers_request,
      scope: nil,
      available_scopes: [] of UUID
    )

    json = {
      "end_to_end_id"          => "E2E-SPEC-007",
      "debtor_account_id"      => TestEnvSepaCT.debtor_account_id.to_s,
      "creditor_iban"          => "DE89370400440532013000",
      "creditor_name"          => "Acme GmbH",
      "amount"                 => 1000,
      "currency"               => "EUR",
      "execution_date"         => "2026-04-01",
      "remittance_information" => "Test",
    }.to_json

    request = Payments::Sepa::CreditTransfers::Api::Requests::CreditTransferRequest.from_json(json)

    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid scope/) do
      Payments::Sepa::CreditTransfers::Initiation::Commands::Request.new.call(request, context)
    end
  end
end
