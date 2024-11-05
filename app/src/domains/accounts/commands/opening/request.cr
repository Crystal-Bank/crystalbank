module CrystalBank::Domains::Accounts
  module Opening
    module Commands
      class Request < ES::Command
        def call(r : Accounts::Api::Requests::OpeningRequest) : UUID
          # TODO: Replace with actor from context
          dummy_actor = UUID.new("00000000-0000-0000-0000-000000000000")

          # Create the account creation request event
          event = Accounts::Opening::Events::Requested.new(
            actor_id: dummy_actor,
            command_handler: self.class.to_s,
            currencies: r.currencies,
            type: r.type
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
