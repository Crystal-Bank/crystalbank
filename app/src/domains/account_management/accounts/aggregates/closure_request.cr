module CrystalBank::Domains::Accounts
  module Closure
    class Aggregate < ES::Aggregate
      @@type = "AccountClosure"

      struct State < ES::Aggregate::State
        property account_id : UUID?
        property reason : CrystalBank::Types::Accounts::ClosureReason?
        property closure_comment : String?
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

      def apply(event : ::Accounts::Closure::Closure::Events::Requested)
        @state.increase_version(event.header.aggregate_version)
        body = event.body.as(::Accounts::Closure::Closure::Events::Requested::Body)
        @state.account_id = body.account_id
        @state.reason = body.reason
        @state.closure_comment = body.closure_comment
      end

      def apply(event : ::Accounts::Closure::Closure::Events::Completed)
        @state.increase_version(event.header.aggregate_version)
        @state.completed = true
      end
    end
  end
end
