module Test::Ledger::Transactions::Events
  module Request
    class Requested
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : ::Ledger::Transactions::Request::Events::Requested
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        scope_id = UUID.new("00000000-0000-0000-0000-100000000001")

        debit_account_id = UUID.new("00000000-0000-0000-0000-100000000000")
        credit_account_id = UUID.new("00000000-0000-0000-0000-200000000000")

        entries = [
          ::Ledger::Transactions::Aggregate::Entry.new(
            account_id: debit_account_id,
            direction: "DEBIT",
            amount: 10000_i64,
            entry_type: "PRINCIPAL",
          ),
          ::Ledger::Transactions::Aggregate::Entry.new(
            account_id: credit_account_id,
            direction: "CREDIT",
            amount: 10000_i64,
            entry_type: "PRINCIPAL",
          ),
        ]

        ::Ledger::Transactions::Request::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          currency: "EUR",
          entries_json: entries.to_json,
          remittance_information: "test remittance information",
          scope_id: scope_id,
        )
      end

      def json_string : String
        debit_account_id = "00000000-0000-0000-0000-100000000000"
        credit_account_id = "00000000-0000-0000-0000-200000000000"

        entries_json = [
          {"account_id" => debit_account_id, "direction" => "DEBIT", "amount" => 10000, "entry_type" => "PRINCIPAL"},
          {"account_id" => credit_account_id, "direction" => "CREDIT", "amount" => 10000, "entry_type" => "PRINCIPAL"},
        ].to_json

        {
          "currency":                "EUR",
          "entries_json":            entries_json,
          "posting_date":            nil,
          "value_date":              nil,
          "remittance_information":  "test remittance information",
          "payment_type":            nil,
          "external_ref":            nil,
          "channel":                 nil,
          "internal_note":           nil,
          "scope_id":                "00000000-0000-0000-0000-100000000001",
        }.to_json
      end
    end

    class Accepted
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : ::Ledger::Transactions::Request::Events::Accepted
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        aggregate_version = 2
        command_handler = "test"
        comment = "test comment"

        ::Ledger::Transactions::Request::Events::Accepted.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          aggregate_version: aggregate_version,
          command_handler: command_handler,
          comment: comment,
        )
      end

      def json_string : String
        {
          "comment": "test comment",
        }.to_json
      end
    end
  end
end
