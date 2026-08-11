module CrystalBank::Domains::Users
  module RemoveRoles
    module Commands
      struct Accept < ES::Command
        getter requestor_id : UUID?

        def initialize(@aggregate_id : UUID, @requestor_id)
        end
      end

      class AcceptHandler < ES::CommandHandler(Accept)
        def handle(command : Accept)
          request_id = command.aggregate_id

          # Hydrate the request aggregate to get intent
          request = Users::RemoveRolesRequest::Aggregate.new(request_id, event_store: @event_store, event_handlers: @event_handlers)
          request.hydrate

          # Guard against double-processing
          return if request.state.completed

          user_id = request.state.user_id.as(UUID)
          role_ids = request.state.role_ids

          # Build the user aggregate
          user = Users::Aggregate.new(user_id, event_store: @event_store, event_handlers: @event_handlers)
          user.hydrate

          # Append the acceptance event to the user aggregate with role_ids in body
          accepted_event = Users::RemoveRoles::Events::Accepted.new(
            actor_id: command.requestor_id,
            aggregate_id: user_id,
            aggregate_version: user.state.next_version,
            command_handler: self.class.to_s,
            role_ids: role_ids,
          )
          @event_store.append(accepted_event)

          # Mark the request aggregate as completed
          completed_event = Users::RemoveRoles::Events::Completed.new(
            actor_id: nil,
            aggregate_id: request_id,
            aggregate_version: request.state.next_version,
            command_handler: self.class.to_s
          )
          @event_store.append(completed_event)
        end
      end
    end
  end
end
