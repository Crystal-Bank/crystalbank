module CrystalBank::Domains::Scopes
  module NameChange
    class Aggregate < ES::Aggregate
      @@type = "ScopeNameChange"

      struct State < ES::Aggregate::State
        property scope_id : UUID?
        property name : String?
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

      def apply(event : ::Scopes::NameChange::Events::Requested)
        @state.increase_version(event.header.aggregate_version)
        body = event.body.as(::Scopes::NameChange::Events::Requested::Body)
        @state.scope_id = body.scope_id
        @state.name = body.name
        @state.requestor_id = event.header.actor_id
      end

      def apply(event : ::Scopes::NameChange::Events::Completed)
        @state.increase_version(event.header.aggregate_version)
        @state.completed = true
      end
    end
  end
end
