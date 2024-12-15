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
    end
  end
end
