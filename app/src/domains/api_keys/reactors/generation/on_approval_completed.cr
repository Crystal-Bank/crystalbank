module CrystalBank::Domains::ApiKeys
  module Reactors
    module Generation
      class OnApprovalCompleted < ES::Reactor
        def call(event : Approvals::Collection::Events::Completed)
          approval = Approvals::Aggregate.new(event.header.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          approval.hydrate

          # Only process if this approval is for an ApiKey
          return unless approval.state.source_aggregate_type == "ApiKey"

          api_key_id = approval.state.source_aggregate_id.as(UUID)

          ApiKeys::Generation::Commands::AcceptHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            ApiKeys::Generation::Commands::Accept.new(aggregate_id: api_key_id)
          )
        end
      end
    end
  end
end
