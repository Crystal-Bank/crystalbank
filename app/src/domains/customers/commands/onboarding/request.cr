module CrystalBank::Domains::Customers
  module Onboarding
    module Commands
      class Request < ES::Command
        def call(r : Customers::Api::Requests::OnboardingRequest) : UUID
          # TODO: Replace with actor from context
          dummy_actor = UUID.new("00000000-0000-0000-0000-000000000000")

          # Check if name is valid
          name = r.name
          raise CrystalBank::Exception::InvalidArgument.new("Name must be at least 2 characters") if name.strip.size < 2

          # Create the customer onboarding request event
          event = Customers::Onboarding::Events::Requested.new(
            actor_id: dummy_actor,
            command_handler: self.class.to_s,
            name: name,
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
