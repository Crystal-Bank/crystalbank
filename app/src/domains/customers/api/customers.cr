require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Customers
  module Api
    class Customers < CrystalBank::Api::Base
      include CrystalBank::Domains::Customers::Api::Requests
      include CrystalBank::Domains::Customers::Api::Responses
      base "/customers"

      # Request onboarding
      # Request the onboarding of a new customer
      #
      # Required permission:
      # - **write:customers.opening**
      @[AC::Route::POST("/onboard", body: :r)]
      def onboard(
        r : OnboardingRequest,
        @[AC::Param::Info(description: "Idempotency key to ensure unique processing", header: "idempotency_key")]
        idempotency_key : UUID
      ) : OnboardingResponse
        aggregate_id = ::Customers::Onboarding::Commands::Request.new.call(r)

        OnboardingResponse.new(aggregate_id)
      end

      # List
      # List all customers
      #
      # Required permission:
      # - **read:customers.list**
      @[AC::Route::GET("/")]
      def list_customers(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20
      ) : ListResponse(Responses::Customer)
        customers = ::Customers::Queries::Customers.new.list(cursor: cursor, limit: limit + 1).map do |a|
          Responses::Customer.new(
            a.id,
            a.name,
            CrystalBank::Types::Customers::Type.parse(a.type)
          )
        end

        ListResponse(Responses::Customer).new(
          url: request.resource,
          data: customers,
          limit: limit
        )
      end
    end
  end
end