module CrystalBank::Domains::Accounts
  module Opening
    module Commands
      class Request < ES::Command
        def call(r : Accounts::Api::Requests::OpeningRequest) : UUID
          # TODO: Replace with actor from context
          dummy_actor = UUID.new("00000000-0000-0000-0000-000000000000")

          # Parse and validate if provided currencies are valid and supported
          parsed_currencies = r.currencies.map { |c| CrystalBank::Types::Currency.new(c).supported! }

          # Parse and validate provided account type
          parsed_type = CrystalBank::Types::AccountType.new(r.type)

          # Create the account creation request event
          event = Accounts::Opening::Events::Requested.new(
            actor_id: dummy_actor,
            command_handler: self.class.to_s,
            currencies: parsed_currencies,
            type: parsed_type
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
