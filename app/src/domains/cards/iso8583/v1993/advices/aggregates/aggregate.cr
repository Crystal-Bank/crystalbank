module CrystalBank::Domains::Cards::Iso8583::V1993::Advices
  class Aggregate < ES::Aggregate
    @@type = "Cards.Iso8583.V1993.Advice"

    struct State < ES::Aggregate::State
      property stan : String?
      property pan_masked : String?
      property amount : Int64?
      property currency : String?
      property terminal_id : String?
      property merchant_id : String?
      property original_data_elements : String?
      property replacement_amounts : String?
      property original_authorization_id : UUID?
      property scope_id : UUID?
      property response_code : String?
      property status : String?
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
