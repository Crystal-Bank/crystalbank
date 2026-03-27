module CrystalBank::Domains::Accounts
  module Blocking
    module Blocking
      class Aggregate < ES::Aggregate
        @@type = "AccountBlock"

        struct State < ES::Aggregate::State
          property account_id : UUID?
          property block_type : CrystalBank::Types::Accounts::BlockType?
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

        def apply(event : ::Accounts::Blocking::Blocking::Events::Requested)
          @state.increase_version(event.header.aggregate_version)
          body = event.body.as(::Accounts::Blocking::Blocking::Events::Requested::Body)
          @state.account_id = body.account_id
          @state.block_type = body.block_type
          @state.reason = body.reason
        end

        def apply(event : ::Accounts::Blocking::Blocking::Events::Completed)
          @state.increase_version(event.header.aggregate_version)
          @state.completed = true
        end
      end
    end
  end
end
