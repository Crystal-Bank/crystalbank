module CrystalBank::Domains::VirtualAccounts
  module Opening
    module Commands
      struct Accept < ES::Command
      end

      class AcceptHandler < ES::CommandHandler(Accept)
        def handle(command : Accept)
          virtual_account = VirtualAccounts::Aggregate.new(command.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          virtual_account.hydrate

          event = VirtualAccounts::Opening::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: command.aggregate_id,
            aggregate_version: virtual_account.state.next_version,
            command_handler: self.class.to_s
          )

          @event_store.append(event)
        end
      end
    end
  end
end
