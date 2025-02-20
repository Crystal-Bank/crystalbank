require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Users
  module Api
    class Users < CrystalBank::Api::Base
      include CrystalBank::Domains::Users::Api::Requests
      include CrystalBank::Domains::Users::Api::Responses
      base "/users"

      # Request onboarding
      # Request the onboarding of a new user
      #
      # Required permission:
      # - **write_users_onboarding_request**
      @[AC::Route::POST("/onboard", body: :r)]
      def open(
        r : OnboardingRequest,
        @[AC::Param::Info(description: "Idempotency key to ensure unique processing", header: "idempotency_key")]
        idempotency_key : UUID,
      ) : OnboardingResponse
        authorized?("write_users_onboarding_request")

        aggregate_id = ::Users::Onboarding::Commands::Request.new.call(r)

        OnboardingResponse.new(aggregate_id)
      end

      # List
      # List all users
      #
      # Required permission:
      # - **read_users_list**
      @[AC::Route::GET("/")]
      def list_users(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20,
      ) : ListResponse(Responses::User)
        authorized?("read_users_list", request_scope: false)

        users = ::Users::Queries::Users.new.list(cursor: cursor, limit: limit + 1).map do |a|
          Responses::User.new(
            a.id,
            a.name,
            a.email
          )
        end

        ListResponse(Responses::User).new(
          url: request.resource,
          data: users,
          limit: limit
        )
      end
    end
  end
end
