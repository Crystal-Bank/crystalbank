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
      # - **write_roles_creation_request**
      @[AC::Route::POST("/create", body: :r)]
      def create(
        r : CreationRequest,
        @[AC::Param::Info(description: "Idempotency key to ensure unique processing", header: "idempotency_key")]
        idempotency_key : UUID,
      ) : CreationResponse
        authorized?("write_roles_creation_request")
        scope = context.scope
        raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

        aggregate_id = UUID.v7
        ::Roles::Creation::Commands::RequestHandler.new.handle(
          ::Roles::Creation::Commands::Request.new(
            aggregate_id: aggregate_id, name: r.name, permissions: r.permissions, scopes: r.scopes,
            scope_id: scope, actor_id: context.user_id, context: context
          )
        )

        CreationResponse.new(aggregate_id)
      end

      # Update permissions
      # Request an update to the permissions of an existing role.
      # The caller must hold write_roles_permissions_update_request.
      # The change is held pending approval from a user with write_roles_permissions_update_approval.
      #
      # Required permission:
      # - **write_roles_permissions_update_request**
      @[AC::Route::POST("/update_permissions", body: :r)]
      def update_permissions(
        r : PermissionsUpdateRequest,
        @[AC::Param::Info(description: "Idempotency key to ensure unique processing", header: "idempotency_key")]
        idempotency_key : UUID,
      ) : Responses::PermissionsUpdateResponse
        authorized?("write_roles_permissions_update_request")
        scope = context.scope
        raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

        result = ::Roles::PermissionsUpdate::Commands::RequestHandler.new.handle(
          ::Roles::PermissionsUpdate::Commands::Request.new(
            aggregate_id: UUID.v7, role_id: r.role_id, permissions: r.permissions, actor_id: context.user_id, scope_id: scope
          )
        )

        Responses::PermissionsUpdateResponse.new(result[:update_request_id])
      end

      # List
      # List all roles
      #
      # Required permission:
      # - **read_roles_list**
      @[AC::Route::GET("/")]
      def list_roles(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20,
      ) : ListResponse(Responses::Role)
        authorized?("read_roles_list", request_scope: false)

        roles = ::Roles::Queries::Roles.new.list(context, cursor: cursor, limit: limit + 1).map do |s|
          Responses::Role.new(
            s.id,
            s.scope_id,
            s.object,
            s.name,
            s.permissions,
            s.scopes,
            s.status
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
