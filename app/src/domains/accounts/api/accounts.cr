require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Accounts
  module Api
    class Accounts < CrystalBank::Api::Base
      include CrystalBank::Domains::Accounts::Api::Requests
      include CrystalBank::Domains::Accounts::Api::Responses
      base "/accounts"

      # Request creation
      # Request the creation of a new account
      #
      # Required permission:
      # - **write:accounts.opening**
      @[AC::Route::POST("/", body: :r)]
      def open(r : OpeningRequest) : OpeningResponse
        aggregate_id = ::Accounts::Opening::Commands::Request.new.call(r)

        OpeningResponse.new(aggregate_id)
      end

      # List
      # List all accounts
      #
      # Required permission:
      # - **read:accounts.list**
      @[AC::Route::GET("/")]
      def list_accounts : ListResponse(Responses::Account)
        accounts = ::Accounts::Queries::Accounts.new.call.map do |a|
          Responses::Account.new(
            a.id,
            a.currencies,
            a.type
          )
        end

        ListResponse(Responses::Account).new(
          url: request.resource,
          data: accounts
        )
      end
    end
  end
end
