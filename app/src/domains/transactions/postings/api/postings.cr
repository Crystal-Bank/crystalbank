require "./concerns/responses"

module CrystalBank::Domains::Transactions::Postings
  module Api
    class Postings < CrystalBank::Api::Base
      include CrystalBank::Domains::Transactions::Postings::Api::Responses
      base "/transactions/postings"

      # List
      # List all postings
      #
      # Required permission:
      # - **read_postings_list**
      @[AC::Route::GET("/")]
      def list_postings(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20,
      ) : ListResponse(Responses::Posting)
        authorized?("read_postings_list", request_scope: false)

        postings = ::Postings::Queries::Postings.new.list(cursor: cursor, limit: limit + 1).map do |a|
          Responses::Posting.new(
            id: a.id,
            account_id: a.account_id,
            amount: a.amount,
            creditor_account_id: a.creditor_account_id,
            currency: a.currency,
            debtor_account_id: a.debtor_account_id,
            remittance_information: a.remittance_information
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
