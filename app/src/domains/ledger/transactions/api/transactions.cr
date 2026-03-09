require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Ledger::Transactions
  module Api
    class Transactions < CrystalBank::Api::Base
      include CrystalBank::Domains::Ledger::Transactions::Api::Requests
      include CrystalBank::Domains::Ledger::Transactions::Api::Responses
      base "/ledger/transactions"

      # Create
      # Submit a low-level ledger money movement with explicit entries
      #
      # Required permission:
      # - **write_ledger_transactions_request**
      @[AC::Route::POST("/", body: :r)]
      def create(r : TransactionRequest) : Responses::TransactionResponse
        authorized?("write_ledger_transactions_request", request_scope: false)

        aggregate_id = ::Ledger::Transactions::Request::Commands::Request.new.call(r, context)

        Responses::TransactionResponse.new(aggregate_id)
      end
    end
  end
end
