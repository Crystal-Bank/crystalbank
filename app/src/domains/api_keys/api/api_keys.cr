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
      # - **write:api_keys.generation**
      @[AC::Route::POST("/generate", body: :r)]
      def generate(
        r : GenerationRequest,
        @[AC::Param::Info(description: "Idempotency key to ensure unique processing", header: "idempotency_key")]
        idempotency_key : UUID
      ) : GenerationResponse
        response = ::ApiKeys::Generation::Commands::Request.new.call(r)

        response
      end

      # List
      # List api keys
      #
      # Required permission:
      # - **write:api_keys.list**
      @[AC::Route::GET("/")]
      def list_api_keys(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20
      ) : ListResponse(Responses::ApiKey)
        api_keys = ::ApiKeys::Queries::ApiKeys.new.list(cursor: cursor, limit: limit + 1).map do |a|
          Responses::ApiKey.new(
            a.id,
            a.name,
            a.created_at
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
