require "./initiation"

module CrystalBank::Domains::Transactions::InternalTransfers
  class Aggregate < ES::Aggregate
    @@type = "Account"

    include CrystalBank::Domains::Transactions::InternalTransfers::Aggregates::Concerns::Initiation

    struct State < ES::Aggregate::State

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
