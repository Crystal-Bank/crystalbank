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
      # - **write:transactions.internal_transfers.initiation.request**
      @[AC::Route::POST("/initiate", body: :r)]
      def open(r : InitiationRequest) : InitiationResponse
        aggregate_id = ::Transactions::InternalTransfers::Initiation::Commands::Request.new.call(r)

        InitiationResponse.new(aggregate_id)
      end
    end
  end
end
