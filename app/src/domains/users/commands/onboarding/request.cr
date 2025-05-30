module CrystalBank::Domains::Users
  module Onboarding
    module Commands
      class Request < ES::Command
        def call(r : Users::Api::Requests::OnboardingRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # TODO: Check if email is valid

          # Create the user creation request event
          event = Users::Onboarding::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            name: r.name,
            email: r.email,
            scope_id: scope,
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
