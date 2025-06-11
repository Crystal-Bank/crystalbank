require "./assign_roles"
require "./onboarding"

module CrystalBank::Domains::Users
  class Aggregate < ES::Aggregate
    @@type = "User"

    include CrystalBank::Domains::Users::Aggregates::Concerns::Onboarding

    struct State < ES::Aggregate::State
      property onboarded : Bool = false
      property name : String?
      property email : String?
      property scope_id : UUID?
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
