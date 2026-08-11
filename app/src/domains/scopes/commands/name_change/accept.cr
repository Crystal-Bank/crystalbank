module CrystalBank::Domains::Scopes
  module NameChange
    module Commands
      struct Accept < ES::Command
        getter requestor_id : UUID?

        def initialize(@aggregate_id : UUID, @requestor_id)
        end
      end

      class AcceptHandler < ES::CommandHandler(Accept)
        def handle(command : Accept)
          name_change_request_id = command.aggregate_id

          # Hydrate the name change request aggregate
          name_change_request = Scopes::NameChange::Aggregate.new(name_change_request_id, event_store: @event_store, event_handlers: @event_handlers)
          name_change_request.hydrate

          # Guard against double-processing
          return if name_change_request.state.completed

          scope_id = name_change_request.state.scope_id.as(UUID)
          new_name = name_change_request.state.name.as(String)

          # Hydrate the scope aggregate to get the next version
          scope = Scopes::Aggregate.new(scope_id, event_store: @event_store, event_handlers: @event_handlers)
          scope.hydrate

          # Apply the approved name onto the Scope aggregate
          accepted_event = Scopes::NameChange::Events::Accepted.new(
            actor_id: command.requestor_id,
            aggregate_id: scope_id,
            aggregate_version: scope.state.next_version,
            command_handler: self.class.to_s,
            name: new_name
          )
          @event_store.append(accepted_event)

          # Mark the name change request itself as completed
          completed_event = Scopes::NameChange::Events::Completed.new(
            actor_id: nil,
            aggregate_id: name_change_request_id,
            aggregate_version: name_change_request.state.next_version,
            command_handler: self.class.to_s
          )
          @event_store.append(completed_event)
        end
      end
    end
  end
end
