module CrystalBank::Domains::VirtualAccounts
  class Aggregate < ES::Aggregate
    @@type = "VirtualAccount"

    struct State < ES::Aggregate::State
      property active : Bool = false
      property name : String?
      property parent_account_id : UUID?
      property customer_ids = Array(UUID).new
      property supported_currencies = Array(CrystalBank::Types::Currencies::Supported).new
      property scope_id : UUID?
      property requestor_id : UUID?
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

    def apply(event : VirtualAccounts::Opening::Events::Requested)
      @state.increase_version(event.header.aggregate_version)

      body = event.body.as(VirtualAccounts::Opening::Events::Requested::Body)
      @state.name = body.name
      @state.parent_account_id = body.parent_account_id
      @state.supported_currencies = body.currencies
      @state.customer_ids = body.customer_ids
      @state.scope_id = body.scope_id
      @state.requestor_id = event.header.actor_id
    end

    def apply(event : VirtualAccounts::Opening::Events::Accepted)
      @state.increase_version(event.header.aggregate_version)
      @state.active = true
    end
  end
end
