module CrystalBank::Domains::Customers
  module Onboarding
    module Commands
      struct Request < ES::Command
        getter name : String
        getter type : CrystalBank::Types::Customers::Type
        getter scope_id : UUID
        getter actor_id : UUID

        def initialize(@aggregate_id : UUID, @name, @type, @scope_id, @actor_id)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request)
          # Check if name is valid
          raise CrystalBank::Exception::InvalidArgument.new("Name must be at least 2 characters") if command.name.strip.size < 2

          # Create the customer onboarding request event
          event = Customers::Onboarding::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: command.aggregate_id,
            command_handler: self.class.to_s,
            encryption_key_id: ES::Config.encryption.create_key,
            name: command.name,
            scope_id: command.scope_id,
            type: command.type
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
