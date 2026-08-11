module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Reactors
    module Initiation
      class OnApprovalCompleted < ES::Reactor
        def call(event : Approvals::Collection::Events::Completed)
          approval = Approvals::Aggregate.new(event.header.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          approval.hydrate

          # Only process if this approval is for a SEPA Credit Transfer
          return unless approval.state.source_aggregate_type == "SepaCreditTransfer"

          payment_id = approval.state.source_aggregate_id.as(UUID)

          Payments::Sepa::CreditTransfers::Initiation::Commands::AcceptHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Payments::Sepa::CreditTransfers::Initiation::Commands::Accept.new(aggregate_id: payment_id)
          )
        end
      end
    end
  end
end
