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

      def available_scopes(permission : CrystalBank::Permissions) : Array(UUID)
        # Check all roles against the requested permission
        roles_scopes = Roles::Queries::RolesPermissions.new.available_scopes(@roles, permission)
        return Array(UUID).new if roles_scopes.empty?

        # Fetch all child scopes
        Scopes::Queries::ScopesTree.new.child_scopes(roles_scopes)
      end
    end
  end
end
