module CrystalBank::Domains::Users
  module RemoveRolesRequest
    class Aggregate < ES::Aggregate
      @@type = "UserRolesRemoval"

      struct State < ES::Aggregate::State
        property user_id : UUID?
        property role_ids = Array(UUID).new
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

      def apply(event : ::Users::RemoveRoles::Events::Requested)
        @state.increase_version(event.header.aggregate_version)
        body = event.body.as(::Users::RemoveRoles::Events::Requested::Body)
        @state.user_id = body.user_id
        @state.role_ids = body.role_ids
        @state.requestor_id = event.header.actor_id
      end

      def apply(event : ::Users::RemoveRoles::Events::Completed)
        @state.increase_version(event.header.aggregate_version)
        @state.completed = true
      end
    end
  end
end
