require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Accounts
  module Api
    class Accounts < CrystalBank::Api::Base
      include CrystalBank::Domains::Accounts::Api::Requests
      include CrystalBank::Domains::Accounts::Api::Responses
      base "/accounts"

      # Request opening
      # Request the opening of a new account
      #
      # Required permission:
      # - **write:accounts.opening**
      @[AC::Route::POST("/open", body: :r)]
      def open(
        r : OpeningRequest,
        @[AC::Param::Info(description: "Idempotency key to ensure unique processing", header: "idempotency_key")]
        idempotency_key : UUID
      ) : OpeningResponse
        aggregate_id = ::Accounts::Opening::Commands::Request.new.call(r)

        OpeningResponse.new(aggregate_id)
      end

      # List
      # List all accounts
      #
      # Required permission:
      # - **read:accounts.list**
      @[AC::Route::GET("/")]
      def list_accounts(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20
      ) : ListResponse(Responses::Account)
        accounts = ::Accounts::Queries::Accounts.new.list(cursor: cursor, limit: limit + 1).map do |a|
          Responses::Account.new(
            a.id,
            a.currencies,
            a.customer_ids,
            CrystalBank::Types::Accounts::Type.parse(a.type)
          )
        end

        ListResponse(Responses::Account).new(
          url: request.resource,
          data: accounts,
          limit: limit
        )
      end
    end
  end
end
