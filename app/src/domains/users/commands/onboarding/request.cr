module CrystalBank::Domains::Users
  module Onboarding
    module Commands
      class Request < ES::Command
        def call(r : Users::Api::Requests::OnboardingRequest) : UUID
          # TODO: Replace with actor from context
          dummy_actor = UUID.new("00000000-0000-0000-0000-000000000000")

          # TODO: Check if email is valid

          # Create the user creation request event
          event = Users::Onboarding::Events::Requested.new(
            actor_id: dummy_actor,
            command_handler: self.class.to_s,
            name: r.name,
            email: r.email
          )

          # Append event to event store
          @event_store.append(event)

          # Return the aggregate ID of the newly created user aggregate
          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
