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
        @event_handlers : ES::EventHandlers = ES::Config.event_handlers
      )
      end

      def available_scopes(permission : String) : Array(UUID)
        CrystalBank.print_verbose("Permissions requested", permission)
        accessible_scopes = [] of UUID  

        # Check all roles against the requested permission

        # Fetch all child scopes 
        Scopes::Queries::ScopesTree.new.child_scopes(UUID.new("01951dca-85b2-7fda-82cb-bbef5f8915e4"))
      end
    end
  end
end
