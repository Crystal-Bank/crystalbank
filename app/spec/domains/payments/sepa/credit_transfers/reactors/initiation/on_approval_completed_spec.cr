require "../../../../../../spec_helper"

module TestEnvSepaCTOnApprovalCompleted
  class_property debtor_account_id : UUID = UUID.random
  class_property settlement_account_id : UUID = UUID.random
end

describe CrystalBank::Domains::Payments::Sepa::CreditTransfers::Reactors::Initiation::OnApprovalCompleted do
  before_all do
    debtor_account_id = UUID.v7
    settlement_account_id = UUID.v7

    [debtor_account_id, settlement_account_id].each do |account_id|
      requested = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
      accepted = Test::Account::Events::Opening::Accepted.new.create(aggr_id: account_id)
      TEST_EVENT_STORE.append(requested)
      TEST_EVENT_STORE.append(accepted)
      Accounts::Projections::Accounts.new.apply(requested)
      Accounts::Projections::Accounts.new.apply(accepted)
    end

    TestEnvSepaCTOnApprovalCompleted.debtor_account_id = debtor_account_id
    TestEnvSepaCTOnApprovalCompleted.settlement_account_id = settlement_account_id
    ENV["SEPA_SETTLEMENT_ACCOUNT_ID"] = settlement_account_id.to_s
  end

  it "creates a ledger transaction with SEPA_CREDIT_TRANSFER entry type on both the customer and settlement account entries" do
    scope_id = UUID.v7

    json = {
      "end_to_end_id"          => "E2E-PROC-APPROVAL-001",
      "debtor_account_id"      => TestEnvSepaCTOnApprovalCompleted.debtor_account_id.to_s,
      "creditor_iban"          => "DE89370400440532013000",
      "creditor_name"          => "Acme GmbH",
      "creditor_bic"           => nil,
      "amount"                 => 15000,
      "currency"               => "EUR",
      "execution_date"         => "2026-04-01",
      "remittance_information" => "Invoice #99",
    }.to_json

    request = Payments::Sepa::CreditTransfers::Api::Requests::CreditTransferRequest.from_json(json)
    payment_id = UUID.v7
    result = Payments::Sepa::CreditTransfers::Initiation::Commands::RequestHandler.new.handle(
      Payments::Sepa::CreditTransfers::Initiation::Commands::Request.new(aggregate_id: payment_id, r: request, actor_id: UUID.v7, scope_id: scope_id)
    )
    approval_id = result[:approval_id]

    # Complete the approval (the Request command creates version 1 via Creation::Requested)
    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    Payments::Sepa::CreditTransfers::Reactors::Initiation::OnApprovalCompleted.new.call(completed_event)

    # The payment aggregate should now be accepted with a linked ledger transaction
    payment = Payments::Sepa::CreditTransfers::Aggregate.new(payment_id)
    payment.hydrate

    payment.state.status.should eq("accepted")
    ledger_transaction_id = payment.state.ledger_transaction_id.as(UUID)

    # Both ledger entries must use SEPA_CREDIT_TRANSFER as their entry type
    ledger = Ledger::Transactions::Aggregate.new(ledger_transaction_id)
    ledger.hydrate

    entries = ledger.state.entries.as(Array(Ledger::Transactions::Aggregate::Entry))
    entries.size.should eq(2)
    entries.each do |entry|
      entry.entry_type.should eq("sepa_credit_transfer")
    end
  end
end
