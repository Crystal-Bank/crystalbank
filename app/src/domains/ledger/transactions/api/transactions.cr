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

      # List postings
      # List all postings from the postings projection
      #
      # Required permission:
      # - **read_postings_list**
      @[AC::Route::GET("/postings")]
      def list_postings(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20,
      ) : ListResponse(Responses::Posting)
        authorized?("read_postings_list", request_scope: false)

        postings = ::Ledger::Transactions::Queries::Postings.new.list(cursor: cursor, limit: limit + 1).map do |p|
          Responses::Posting.new(
            p.id,
            p.account_id,
            p.direction,
            p.amount,
            p.entry_type,
            p.currency,
            p.posting_date.to_rfc3339,
            p.value_date.to_rfc3339,
            p.remittance_information,
            p.payment_type,
            p.external_ref,
            p.channel
          )
        end

        ListResponse(Responses::Posting).new(
          url: request.resource,
          data: postings,
          limit: limit
        )
      end
    end
  end
end
