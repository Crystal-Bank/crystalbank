module CrystalBank::Domains::Users
  module Onboarding
    module Commands
      struct Request < ES::Command
        getter name : String
        getter email : String
        getter scope_id : UUID
        getter actor_id : UUID

        def initialize(@aggregate_id : UUID, @name, @email, @scope_id, @actor_id)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request)
          # TODO: Check if email is valid

          # Create the user creation request event
          event = Users::Onboarding::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: command.aggregate_id,
            command_handler: self.class.to_s,
            name: command.name,
            email: command.email,
            scope_id: command.scope_id,
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
