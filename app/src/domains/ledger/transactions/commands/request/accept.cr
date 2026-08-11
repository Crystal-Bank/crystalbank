module CrystalBank::Domains::Ledger::Transactions
  module Request
    module Commands
      struct Accept < ES::Command
      end

      class AcceptHandler < ES::CommandHandler(Accept)
        def handle(command : Accept)
          aggregate = Ledger::Transactions::Aggregate.new(command.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          aggregate.hydrate

          event = Ledger::Transactions::Request::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: command.aggregate_id,
            aggregate_version: aggregate.state.next_version,
            command_handler: self.class.to_s
          )

          @event_store.append(event)
        end
      end
    end
  end
end
