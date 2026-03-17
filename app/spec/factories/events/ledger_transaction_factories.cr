module Test::Ledger::Transactions::Events
  module Request
    class Requested
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : ::Ledger::Transactions::Request::Events::Requested
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        command_handler = "test"
        comment = "test comment"
        scope_id = UUID.new("00000000-0000-0000-0000-100000000001")
        currency = CrystalBank::Types::Currencies::Supported::EUR
        remittance_information = "test remittance information"
        posting_date = Time::Format::ISO_8601_DATE.parse("2026-03-11")
        value_date = Time::Format::ISO_8601_DATE.parse("2026-03-12")
        payment_type = "SEPA_CREDIT_TRANSFER"
        external_ref = "ext-ref"
        channel = "api"

        debit_account_id = UUID.new("00000000-0000-0000-0000-100000000000")
        credit_account_id = UUID.new("00000000-0000-0000-0000-200000000000")

        entries = [
          ::Ledger::Transactions::Aggregate::Entry.new(
            id: UUID.new("00000000-0000-0000-0000-000000000010"),
            account_id: debit_account_id,
            direction: "debit",
            amount: 10000_i64,
            entry_type: "PRINCIPAL",
          ),
          ::Ledger::Transactions::Aggregate::Entry.new(
            id: UUID.new("00000000-0000-0000-0000-000000000020"),
            account_id: credit_account_id,
            direction: "credit",
            amount: 10000_i64,
            entry_type: "PRINCIPAL",
          ),
        ]

        ::Ledger::Transactions::Request::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          currency: currency,
          entries_json: entries.to_json,
          posting_date: posting_date,
          value_date: value_date,
          remittance_information: remittance_information,
          payment_type: payment_type,
          external_ref: external_ref,
          channel: channel,
          scope_id: scope_id,
          command_handler: command_handler,
          comment: comment,
        )
      end

      def json_string : String
        debit_account_id = "00000000-0000-0000-0000-100000000000"
        credit_account_id = "00000000-0000-0000-0000-200000000000"

        entries_json = [
          {"id" => "00000000-0000-0000-0000-000000000010", "account_id" => debit_account_id, "direction" => "debit", "amount" => 10000, "entry_type" => "PRINCIPAL"},
          {"id" => "00000000-0000-0000-0000-000000000020", "account_id" => credit_account_id, "direction" => "credit", "amount" => 10000, "entry_type" => "PRINCIPAL"},
        ].to_json

        {
          "comment":                "test comment",
          "channel":                "api",
          "currency":               "eur",
          "entries_json":           entries_json,
          "external_ref":           "ext-ref",
          "payment_type":           "SEPA_CREDIT_TRANSFER",
          "posting_date":           "2026-03-11T00:00:00Z",
          "remittance_information": "test remittance information",
          "scope_id":               "00000000-0000-0000-0000-100000000001",
          "value_date":             "2026-03-12T00:00:00Z",
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
