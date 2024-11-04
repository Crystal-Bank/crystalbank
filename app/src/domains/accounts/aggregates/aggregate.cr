require "./opening"

module CrystalBank::Domains::Accounts
  class Aggregate < ES::Aggregate
    @@type = "Account"

    include CrystalBank::Domains::Accounts::Aggregates::Concerns::Opening

    struct State < ES::Aggregate::State
      property open : Bool = false
      property supported_currencies = Array(CrystalBank::Types::Currency).new
      property type : CrystalBank::Types::AccountType?
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
