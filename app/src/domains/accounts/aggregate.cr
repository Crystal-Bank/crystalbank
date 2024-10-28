module CrystalBank::Domains::Accounts
  class Aggregate < ES::Aggregate
    @@type = "Transaction"

    struct State < ES::Aggregate::State; end

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

    # Apply 'Accounts::Opening::Events::Requested' to the aggregate state
    def apply(event : CrystalBank::Domains::Accounts::Opening::Events::Requested)
      @state.increase_version(event.header.aggregate_version)

      body = event.body.as(CrystalBank::Domains::Accounts::Opening::Events::Requested::Body)
    end
  end
end
