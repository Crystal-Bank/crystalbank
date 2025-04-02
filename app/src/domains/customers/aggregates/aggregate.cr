require "./onboarding"

module CrystalBank::Domains::Customers
  class Aggregate < ES::Aggregate
    @@type = "Customer"

    include CrystalBank::Domains::Customers::Aggregates::Concerns::Onboarding

    struct State < ES::Aggregate::State
      property name : String?
      property onboarded : Bool = false
      property scope_id : UUID?
      property type : CrystalBank::Types::Customers::Type?
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
