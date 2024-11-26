module Test::Transactions::InternalTransfers::Events
  module Initiation
    class Accepted
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : ::Transactions::InternalTransfers::Initiation::Events::Accepted
        account_type = CrystalBank::Types::Accounts::Type.parse("checking")
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        aggregate_version = 2
        amount = 100
        command_handler = "test"
        comment = "test comment"
        creditor_account_id = UUID.new("00000000-0000-0000-0000-200000000000")
        currency = CrystalBank::Types::Currencies::Supported.parse("eur")
        debtor_account_id = UUID.new("00000000-0000-0000-0000-100000000000")

        ::Transactions::InternalTransfers::Initiation::Events::Accepted.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          aggregate_version: aggregate_version,
          command_handler: command_handler,
          comment: comment
        )
      end

      def json_string : String
        {
          "comment": "test comment",
        }.to_json
      end
    end

    class Requested
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : ::Transactions::InternalTransfers::Initiation::Events::Requested
        account_type = CrystalBank::Types::Accounts::Type.parse("checking")
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        amount = 100
        command_handler = "test"
        comment = "test comment"
        creditor_account_id = UUID.new("00000000-0000-0000-0000-200000000000")
        currency = CrystalBank::Types::Currencies::Supported.parse("eur")
        debtor_account_id = UUID.new("00000000-0000-0000-0000-100000000000")
        remittance_information = "test remittance information"

        ::Transactions::InternalTransfers::Initiation::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          amount: amount,
          command_handler: command_handler,
          comment: comment,
          creditor_account_id: creditor_account_id,
          currency: currency,
          debtor_account_id: debtor_account_id,
          remittance_information: remittance_information
        )
      end

      def json_string : String
        {
          "comment":                "test comment",
          "currency":               "eur",
          "amount":                 100,
          "creditor_account_id":    "00000000-0000-0000-0000-200000000000",
          "debtor_account_id":      "00000000-0000-0000-0000-100000000000",
          "remittance_information": "test remittance information",
        }.to_json
      end
    end
  end
end
