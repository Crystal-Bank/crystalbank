module CrystalBank::Domains::Customers
  module Onboarding
    module Commands
      struct Accept < ES::Command
      end

      class AcceptHandler < ES::CommandHandler(Accept)
        def handle(command : Accept)
          # Build the customer aggregate
          customer = Customers::Aggregate.new(command.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          customer.hydrate

          # Create the customer onboarding acceptance event
          event = Customers::Onboarding::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: command.aggregate_id,
            aggregate_version: customer.state.next_version,
            command_handler: self.class.to_s
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
