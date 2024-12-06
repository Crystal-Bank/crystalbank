require "./generation"

module CrystalBank::Domains::ApiKeys
  class Aggregate < ES::Aggregate
    @@type = "ApiKey"

    include CrystalBank::Domains::ApiKeys::Aggregates::Concerns::Generation

    struct State < ES::Aggregate::State
      property active : Bool = false
      property name : String?
      property user_id : UUID?
      property api_secret : String?
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