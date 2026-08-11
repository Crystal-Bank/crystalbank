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
        scope = context.scope
        raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

        aggregate_id = UUID.v7
        ::Scopes::Creation::Commands::RequestHandler.new.handle(
          ::Scopes::Creation::Commands::Request.new(
            aggregate_id: aggregate_id, name: r.name, parent_scope_id: r.parent_scope_id, scope_id: scope, actor_id: context.user_id
          )
        )

        CreationResponse.new(aggregate_id)
      end

      # Request name change
      # Request renaming of an existing active scope
      #
      # Required permission:
      # - **write_scopes_name_change_request**
      @[AC::Route::POST("/change-name", body: :r)]
      def change_name(
        r : NameChangeRequest,
        @[AC::Param::Info(description: "Idempotency key to ensure unique processing", header: "idempotency_key")]
        idempotency_key : UUID,
      ) : NameChangeResponse
        authorized?("write_scopes_name_change_request")
        scope = context.scope
        raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

        result = ::Scopes::NameChange::Commands::RequestHandler.new.handle(
          ::Scopes::NameChange::Commands::Request.new(
            aggregate_id: UUID.v7, target_scope_id: r.scope_id, name: r.name, actor_id: context.user_id, scope_id: scope
          )
        )

        NameChangeResponse.new(result[:name_change_request_id])
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
        @[AC::Param::Info(description: "Optional comma-separated list of scope UUIDs to filter by")]
        ids : String? = nil,
      ) : ListResponse(Responses::Scope)
        authorized?("read_scopes_list", request_scope: false)

        uuids = ids.try(&.split(",").compact_map { |s| UUID.new(s.strip) rescue nil })
        scopes = ::Scopes::Queries::Scopes.new.list(context, cursor: cursor, limit: limit + 1, uuids: uuids).map do |s|
          Responses::Scope.new(
            s.id,
            s.scope_id,
            s.name,
            s.parent_scope_id,
            s.status
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
