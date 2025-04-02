module CrystalBank::Domains::Customers
  module Onboarding
    module Commands
      class Request < ES::Command
        def call(r : Customers::Api::Requests::OnboardingRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # Check if name is valid
          name = r.name
          raise CrystalBank::Exception::InvalidArgument.new("Name must be at least 2 characters") if name.strip.size < 2

          # Create the customer onboarding request event
          event = Customers::Onboarding::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            name: name,
            scope_id: scope,
            type: r.type
          )

          # Append event to event store
          @event_store.append(event)

          # Return the aggregate ID of the newly created customer aggregate
          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
