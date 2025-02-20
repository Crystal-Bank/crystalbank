require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Roles
  module Api
    class Roles < CrystalBank::Api::Base
      include CrystalBank::Domains::Roles::Api::Requests
      include CrystalBank::Domains::Roles::Api::Responses
      base "/roles"

      # Request creation
      # Request the creation of a new role
      #
      # Required permission:
      # - **write:roles.creation.request**
      @[AC::Route::POST("/create", body: :r)]
      def create(
        r : CreationRequest,
        @[AC::Param::Info(description: "Idempotency key to ensure unique processing", header: "idempotency_key")]
        idempotency_key : UUID,
      ) : CreationResponse
        authorized?("write:roles.creation.request")

        aggregate_id = ::Roles::Creation::Commands::Request.new.call(r)

        CreationResponse.new(aggregate_id)
      end

      # List
      # List all roles
      #
      # Required permission:
      # - **read:roles.list**
      @[AC::Route::GET("/")]
      def list_roles(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20,
      ) : ListResponse(Responses::Role)
        authorized?("read:roles.list", request_scope: false)

        roles = ::Roles::Queries::Roles.new.list(cursor: cursor, limit: limit + 1).map do |s|
          Responses::Role.new(
            s.id,
            s.name,
            s.permissions,
            s.scopes
          )
        end

        ListResponse(Responses::Role).new(
          url: request.resource,
          data: roles,
          limit: limit
        )
      end
    end
  end
end
