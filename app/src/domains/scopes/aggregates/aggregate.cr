require "./creation"

module CrystalBank::Domains::Scopes
  class Aggregate < ES::Aggregate
    @@type = "Scope"

    include CrystalBank::Domains::Scopes::Aggregates::Concerns::Creation

    struct State < ES::Aggregate::State
      property name : String?
      property parent_scope_id : UUID?
    end

    getter state : State

    def initialize(
      aggregate_id : UUID,
      @event_store : ES::EventStore = ES::Config.event_store,
      @event_handlers : ES::EventHandlers = ES::Config.event_handlers
    )
      @aggregate_version = 0
      @state = State.new(aggregate_id)
      @state.set_type(@@type)
    end
  end
end
