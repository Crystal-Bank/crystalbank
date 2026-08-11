module CrystalBank::Domains::Roles
  module PermissionsUpdate
    module Commands
      struct Accept < ES::Command
        getter requestor_id : UUID?

        def initialize(@aggregate_id : UUID, @requestor_id)
        end
      end

      class AcceptHandler < ES::CommandHandler(Accept)
        def handle(command : Accept)
          update_request_id = command.aggregate_id

          # Hydrate the permissions update request aggregate
          update_request = Roles::PermissionsUpdate::Aggregate.new(update_request_id, event_store: @event_store, event_handlers: @event_handlers)
          update_request.hydrate

          # Guard against double-processing
          return if update_request.state.completed

          role_id = update_request.state.role_id.as(UUID)
          permissions = update_request.state.permissions.as(Array(CrystalBank::Permissions))

          # Hydrate the role aggregate to get the next version
          role = Roles::Aggregate.new(role_id, event_store: @event_store, event_handlers: @event_handlers)
          role.hydrate

          # Apply the approved permissions onto the Role aggregate
          accepted_event = Roles::PermissionsUpdate::Events::Accepted.new(
            actor_id: command.requestor_id,
            aggregate_id: role_id,
            aggregate_version: role.state.next_version,
            command_handler: self.class.to_s,
            permissions: permissions
          )
          @event_store.append(accepted_event)

          # Mark the update request itself as completed
          completed_event = Roles::PermissionsUpdate::Events::Completed.new(
            actor_id: nil,
            aggregate_id: update_request_id,
            aggregate_version: update_request.state.next_version,
            command_handler: self.class.to_s
          )
          @event_store.append(completed_event)
        end
      end
    end
  end
end
