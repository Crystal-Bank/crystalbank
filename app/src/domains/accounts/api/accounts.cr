require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Accounts
  module Api
    class Accounts < CrystalBank::Api::Base
      include ::Accounts::Api::Requests
      include ::Accounts::Api::Responses
      base "/accounts"

      # Request creation
      # Request the creation of a new account
      #
      # Required permission:
      # - **write:accounts.opening**
      @[AC::Route::POST("/", body: :r)]
      def open(r : Request) : OpeningResponse
        # authorized?("write:accounts.opening")

        aggregate_id = ::Accounts::Opening::Commands::Request.new.call(r)

        OpeningResponse.new(aggregate_id)
      end
    end
  end
end
