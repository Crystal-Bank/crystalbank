require "./block_request_concerns"

module CrystalBank::Domains::Accounts
  module Blocking
    class Aggregate < ES::Aggregate
      @@type = "AccountBlockRequest"

      include CrystalBank::Domains::Accounts::Blocking::Aggregates::Concerns::BlockRequest

      struct State < ES::Aggregate::State
        property account_id : UUID?
        property block_type : CrystalBank::Types::Accounts::BlockType?
        property action : String?
        property reason : String?
        property completed : Bool = false
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
end
