require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Transactions::InternalTransfers
  module Api
    class InternalTransfers < CrystalBank::Api::Base
      include CrystalBank::Domains::Transactions::InternalTransfers::Api::Requests
      include CrystalBank::Domains::Transactions::InternalTransfers::Api::Responses
      base "/transactions/internal_transfers"

      # Request initiation
      # Request initiation of an internal transfer
      #
      # Required permission:
      # - **write_transactions_internal_transfers_initiation_request**
      @[AC::Route::POST("/initiate", body: :r)]
      def initiate(r : InitiationRequest) : InitiationResponse
        authorized?("write_transactions_internal_transfers_initiation_request")

        aggregate_id = ::Transactions::InternalTransfers::Initiation::Commands::Request.new.call(r, context)

        InitiationResponse.new(aggregate_id)
      end
    end
  end
end
