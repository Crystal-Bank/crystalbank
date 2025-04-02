require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Scopes
  module Api
    class Scopes < CrystalBank::Api::Base
      include CrystalBank::Domains::Scopes::Api::Requests
      include CrystalBank::Domains::Scopes::Api::Responses
      base "/scopes"

      # Request creation
      # Request the creation of a new scope
      #
      # Required permission:
      # - **write_scopes_creation_request**
      @[AC::Route::POST("/create", body: :r)]
      def create(
        r : CreationRequest,
        @[AC::Param::Info(description: "Idempotency key to ensure unique processing", header: "idempotency_key")]
        idempotency_key : UUID,
      ) : CreationResponse
        authorized?("write_scopes_creation_request")

        aggregate_id = ::Scopes::Creation::Commands::Request.new.call(r, context)

        CreationResponse.new(aggregate_id)
      end

      # List
      # List all scopes
      #
      # Required permission:
      # - **read_scopes_list**
      @[AC::Route::GET("/")]
      def list_scopes(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20,
      ) : ListResponse(Responses::Scope)
        authorized?("read_scopes_list", request_scope: false)

        scopes = ::Scopes::Queries::Scopes.new.list(cursor: cursor, limit: limit + 1).map do |s|
          Responses::Scope.new(
            s.id,
            s.name,
            s.parent_scope_id
          )
        end

        ListResponse(Responses::Scope).new(
          url: request.resource,
          data: scopes,
          limit: limit
        )
      end
    end
  end
end
