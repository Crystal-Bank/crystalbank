module CrystalBank::Domains::Users
  module RemoveRoles
    module Commands
      struct Request < ES::Command
        getter user_id : UUID
        getter role_ids : Array(UUID)
        getter actor_id : UUID
        getter scope_id : UUID

        def initialize(@aggregate_id : UUID, @user_id, @role_ids, @actor_id, @scope_id)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request)
          # Build the user aggregate and validate role assignments
          user = Users::Aggregate.new(command.user_id, event_store: @event_store, event_handlers: @event_handlers)
          user.hydrate

          missing_roles = command.role_ids - user.state.role_ids
          if !missing_roles.empty?
            raise CrystalBank::Exception::InvalidArgument.new("The roles [#{missing_roles.map(&.to_s).join(", ")}] are not assigned to the user")
          end

          # Create the request aggregate under the given aggregate ID
          event = Users::RemoveRoles::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: command.aggregate_id,
            command_handler: self.class.to_s,
            user_id: command.user_id,
            role_ids: command.role_ids,
            scope_id: command.scope_id,
          )

          @event_store.append(event)
        end
      end
    end
  end
end
