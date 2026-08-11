module CrystalBank::Domains::Ledger::Transactions
  module Reactors
    module Request
      class OnRequested < ES::Reactor
        def call(event : Ledger::Transactions::Request::Events::Requested)
          Ledger::Transactions::Request::Commands::AcceptHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Ledger::Transactions::Request::Commands::Accept.new(aggregate_id: event.header.aggregate_id)
          )
        end
      end
    end
  end
end
