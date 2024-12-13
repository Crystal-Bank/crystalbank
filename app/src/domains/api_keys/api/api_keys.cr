require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::ApiKeys
  module Api
    class ApiKeys < CrystalBank::Api::Base
      include CrystalBank::Domains::ApiKeys::Api::Requests
      include CrystalBank::Domains::ApiKeys::Api::Responses
      base "/api_keys"

      # Request generation
      # Request the generation of a new api-key
      #
      # Required permission:
      # - **write:api_keys.generation.request**
      @[AC::Route::POST("/generate", body: :r)]
      def generate(
        r : GenerationRequest,
        @[AC::Param::Info(description: "Idempotency key to ensure unique processing", header: "idempotency_key")]
        idempotency_key : UUID
      ) : GenerationResponse
        authorized?("write:api_keys.generation.request")

        response = ::ApiKeys::Generation::Commands::Request.new.call(r)

        response
      end

      # Request revocation
      # Request the revocation of a new api-key
      #
      # Required permission:
      # - **write:api_keys.revocation.request**
      @[AC::Route::PATCH("/:id/revoke", body: :r)]
      def revoke(
        @[AC::Param::Info(description: "ID of the api key")]
        id : UUID,
        r : RevocationRequest,
      )
        authorized?("write:api_keys.revocation.request", request_scope: false)

        response = ::ApiKeys::Revocation::Commands::Request.new.call(id, r)

        response ? head(:accepted) : head(:internal_server_error)
      end

      # List
      # List api keys
      #
      # Required permission:
      # - **read:api_keys.list**
      @[AC::Route::GET("/")]
      def list_api_keys(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20
      ) : ListResponse(Responses::ApiKey)
        authorized?("read:api_keys.list", request_scope: false)

        api_keys = ::ApiKeys::Queries::ApiKeys.new.list(cursor: cursor, limit: limit + 1).map do |a|
          Responses::ApiKey.new(
            a.id,
            a.active,
            a.name,
            a.created_at,
            a.revoked_at
          )
        end

        ListResponse(Responses::ApiKey).new(
          url: request.resource,
          data: api_keys,
          limit: limit
        )
      end
    end
  end
end
