require "./opening"
require "./blocking"
require "./closure"

module CrystalBank::Domains::Accounts
  class Aggregate < ES::Aggregate
    @@type = "Account"

    include CrystalBank::Domains::Accounts::Aggregates::Concerns::Opening
    include CrystalBank::Domains::Accounts::Aggregates::Concerns::Blocking
    include CrystalBank::Domains::Accounts::Aggregates::Concerns::Closure

    struct State < ES::Aggregate::State
      property open : Bool = false
      property name : String?
      property customer_ids = Array(UUID).new
      property supported_currencies = Array(CrystalBank::Types::Currencies::Supported).new
      property scope_id : UUID?
      property type : CrystalBank::Types::Accounts::Type?
      property requestor_id : UUID?
      property active_blocks = Array(CrystalBank::Types::Accounts::BlockType).new
      property closure_pending : Bool = false
      property closure_reason : CrystalBank::Types::Accounts::ClosureReason?
      property closure_comment : String?
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
