module Test::Payments::Sepa::CreditTransfers::Events
  SCOPE_ID              = UUID.new("00000000-0000-0000-0000-100000000001")
  DEBTOR_ACCOUNT_ID     = UUID.new("00000000-0000-0000-0000-100000000010")
  SETTLEMENT_ACCOUNT_ID = UUID.new("00000000-0000-0000-0000-100000000020")
  LEDGER_TX_ID          = UUID.new("00000000-0000-0000-0000-200000000001")

  module Initiation
    class Requested
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Payments::Sepa::CreditTransfers::Initiation::Events::Requested
        Payments::Sepa::CreditTransfers::Initiation::Events::Requested.new(
          actor_id: UUID.new("00000000-0000-0000-0000-000000000000"),
          aggregate_id: aggr_id,
          command_handler: "test",
          comment: "test comment",
          end_to_end_id: "E2E-TEST-001",
          debtor_account_id: DEBTOR_ACCOUNT_ID,
          settlement_account_id: SETTLEMENT_ACCOUNT_ID,
          creditor_iban: "DE89370400440532013000",
          creditor_name: "Test Creditor GmbH",
          creditor_bic: nil,
          amount: 10000_i64,
          execution_date: Time::Format::ISO_8601_DATE.parse("2026-03-11"),
          remittance_information: "Test payment",
          scope_id: SCOPE_ID,
        )
      end

      def json_string : String
        {
          "comment":                "test comment",
          "end_to_end_id":          "E2E-TEST-001",
          "debtor_account_id":      "00000000-0000-0000-0000-100000000010",
          "settlement_account_id":  "00000000-0000-0000-0000-100000000020",
          "creditor_iban":          "DE89370400440532013000",
          "creditor_name":          "Test Creditor GmbH",
          "creditor_bic":           nil,
          "amount":                 10000,
          "execution_date":         "2026-03-11T00:00:00Z",
          "remittance_information": "Test payment",
          "scope_id":               "00000000-0000-0000-0000-100000000001",
        }.to_json
      end
    end

    class Accepted
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Payments::Sepa::CreditTransfers::Initiation::Events::Accepted
        Payments::Sepa::CreditTransfers::Initiation::Events::Accepted.new(
          actor_id: UUID.new("00000000-0000-0000-0000-000000000000"),
          aggregate_id: aggr_id,
          aggregate_version: 2,
          command_handler: "test",
          comment: "test comment",
          ledger_transaction_id: LEDGER_TX_ID,
        )
      end

      def json_string : String
        {
          "comment":                "test comment",
          "ledger_transaction_id":  "00000000-0000-0000-0000-200000000001",
        }.to_json
      end
    end
  end
end
