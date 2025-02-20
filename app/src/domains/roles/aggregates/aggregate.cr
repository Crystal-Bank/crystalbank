require "./creation"

module CrystalBank::Domains::Roles
  class Aggregate < ES::Aggregate
    @@type = "Role"

    include CrystalBank::Domains::Roles::Aggregates::Concerns::Creation

    struct State < ES::Aggregate::State
      property name : String?
      property permissions : Array(CrystalBank::Permissions)?
      property scopes : Array(UUID)?
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
  end
end
