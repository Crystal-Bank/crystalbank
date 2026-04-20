module CrystalBank::Domains::Roles
  module PermissionsUpdate
    class Aggregate < ES::Aggregate
      @@type = "RolePermissionsUpdate"

      struct State < ES::Aggregate::State
        property role_id : UUID?
        property permissions : Array(CrystalBank::Permissions)?
        property requestor_id : UUID?
        property completed : Bool = false
      end

      getter state : State

      def initialize(
        aggregate_id : UUID,
        @event_store : ES::EventStore = ES::Config.event_store,
        @event_handlers : ES::EventHandlers = ES::Config.event_handlers,
      )
        @aggregate_version = 0
        @state = State.new(aggregate_id)
        @state.set_type(@@type)
      end

      def apply(event : ::Roles::PermissionsUpdate::Events::Requested)
        @state.increase_version(event.header.aggregate_version)
        body = event.body.as(::Roles::PermissionsUpdate::Events::Requested::Body)
        @state.role_id = body.role_id
        @state.permissions = body.permissions
        @state.requestor_id = event.header.actor_id
      end

      def apply(event : ::Roles::PermissionsUpdate::Events::Completed)
        @state.increase_version(event.header.aggregate_version)
        @state.completed = true
      end
    end
  end
end
