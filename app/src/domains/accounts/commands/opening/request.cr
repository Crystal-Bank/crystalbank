module CrystalBank::Domains::Accounts
  module Opening
    module Commands
      class Request < ES::Command
        def call : UUID
          # Create the account creation request event
          event = Accounts::Opening::Events::Requested.new(
            actor: UUID.v7,
            command_handler: self.class.to_s
          )

          # Append event to event store
          @event_store.append(event)

          # Return the aggregate ID of the newly created account aggregate
          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
