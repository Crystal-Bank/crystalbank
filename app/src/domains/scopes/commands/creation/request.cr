module CrystalBank::Domains::Scopes
  module Creation
    module Commands
      struct Request < ES::Command
        getter name : String
        getter parent_scope_id : UUID?
        getter scope_id : UUID
        getter actor_id : UUID

        def initialize(@aggregate_id : UUID, @name, @parent_scope_id, @scope_id, @actor_id)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request)
          # Check if provided parent scope can be found and is active
          # Default to the current x-scope when no explicit parent is provided
          parent_scope_id = command.parent_scope_id || command.scope_id
          unless parent_scope_id.nil?
            aggregate = Scopes::Aggregate.new(parent_scope_id, event_store: @event_store, event_handlers: @event_handlers)
            begin
              aggregate.hydrate
            rescue ES::Exception::NotFound
              raise CrystalBank::Exception::InvalidArgument.new("Parent scope is not active")
            end
            raise CrystalBank::Exception::InvalidArgument.new("Parent scope is not active") unless aggregate.state.accepted
          end

          # Create the scope creation request event
          event = Scopes::Creation::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: command.aggregate_id,
            command_handler: self.class.to_s,
            name: command.name,
            parent_scope_id: parent_scope_id,
            scope_id: command.scope_id,
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
