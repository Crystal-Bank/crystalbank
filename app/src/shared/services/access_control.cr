# TODO: Implement
#
module CrystalBank
  module Services
    class AccessControl
      getter roles : Array(UUID)

      def initialize(
        @roles : Array(UUID),
        @projection_db : DB::Database = ES::Config.projection_database,
        @event_store : ES::EventStore = ES::Config.event_store,
        @event_handlers : ES::EventHandlers = ES::Config.event_handlers,
      )
      end

      def available_scopes(permission : CrystalBank::Permissions, request_scope : UUID?) : Array(UUID)
        # Check all roles against the requested permission
        roles_scopes = Roles::Queries::RolesPermissions.new.available_scopes(@roles, permission)
        return Array(UUID).new if roles_scopes.empty?

        roles_scopes_tree = Scopes::Queries::ScopesTree.new.child_scopes(roles_scopes)

        available_scope_ids = if request_scope.nil?
          roles_scopes_tree
        else  
          request_scopes_tree = Scopes::Queries::ScopesTree.new.child_scopes(request_scope)

          # Return the intersection of available scopes tree based on the role and the requested scope tree
          roles_scopes_tree && request_scopes_tree
        end

        available_scope_ids
      end
    end
  end
end
