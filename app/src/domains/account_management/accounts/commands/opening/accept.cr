module CrystalBank::Domains::Accounts
  module Opening
    module Commands
      struct Accept < ES::Command
      end

      class AcceptHandler < ES::CommandHandler(Accept)
        def handle(command : Accept)
          # Build the account aggregate
          account = Accounts::Aggregate.new(command.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          account.hydrate

          # Create the account opening acceptance event
          event = Accounts::Opening::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: command.aggregate_id,
            aggregate_version: account.state.next_version,
            command_handler: self.class.to_s
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
