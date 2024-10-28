module CrystalBank::Domains::Accounts
  module Opening
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id : UUID = @aggregate_id
          # TODO: Run checks to check the legitimacy of the account opening

          # Build the account aggregate
          aggregate = Accounts::Aggregate.new(aggregate_id)
          aggregate.hydrate

          next_version = aggregate.state.next_version

          # Create the account creation acceptance event
          event = Accounts::Opening::Events::Accepted.new(
            actor: nil,
            aggregate_id: aggregate_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
