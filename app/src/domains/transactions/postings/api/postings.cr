require "./concerns/responses"

module CrystalBank::Domains::Transactions::Postings
  module Api
    class Postings < CrystalBank::Api::Base
      include CrystalBank::Domains::Transactions::Postings::Api::Responses
      base "/postings"

      # List
      # List all postings
      #
      # Required permission:
      # - **read:postings.list**
      @[AC::Route::GET("/")]
      def list_postings : ListResponse(Responses::Posting)
        postings = ::Postings::Queries::Postings.new.call.map do |a|
          Responses::Posting.new(
            id: a.id,
            account_id: a.account_id,
            amount: a.amount,
            creditor_account_id: a.creditor_account_id,
            debtor_account_id: a.debtor_account_id,
            remittance_information: a.remittance_information
          )
        end

        ListResponse(Responses::Posting).new(
          url: request.resource,
          data: postings
        )
      end
    end
  end
end
