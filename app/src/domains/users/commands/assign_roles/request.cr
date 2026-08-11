module CrystalBank::Domains::Users
  module AssignRoles
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
          # Check if provided roles do exist
          repository = Users::Repositories::Roles.new
          command.role_ids.each { |role_id| repository.exists!(role_id) }

          # Build the user aggregate
          user = Users::Aggregate.new(command.user_id, event_store: @event_store, event_handlers: @event_handlers)
          user.hydrate

          # Check if roles are already assigned to the user
          common_roles = command.role_ids & user.state.role_ids
          if !common_roles.empty?
            raise CrystalBank::Exception::InvalidArgument.new("The roles [#{common_roles.map(&.to_s).join(", ")}] are already assigned to the user")
          end

          # Create the request aggregate under the given aggregate ID
          event = Users::AssignRoles::Events::Requested.new(
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
