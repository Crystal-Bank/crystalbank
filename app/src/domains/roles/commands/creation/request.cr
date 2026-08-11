module CrystalBank::Domains::Roles
  module Creation
    module Commands
      struct Request < ES::Command
        getter name : String
        getter permissions : Array(CrystalBank::Permissions)
        getter scopes : Array(UUID)
        getter scope_id : UUID
        getter actor_id : UUID
        getter context : CrystalBank::Api::Context

        def initialize(@aggregate_id : UUID, @name, @permissions, @scopes, @scope_id, @actor_id, @context)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request)
          scopes = command.scopes

          # Validate that all provided scope IDs exist and are active
          raise CrystalBank::Exception::InvalidArgument.new("Role needs to be applicable to at least one scope") if scopes.empty?

          active_scope_ids = Scopes::Queries::Scopes.new.find_all(command.context, scopes, status: "active").map(&.id)
          invalid_scopes = scopes - active_scope_ids
          raise CrystalBank::Exception::InvalidArgument.new("Invalid or inactive scopes: #{invalid_scopes.map(&.to_s).join(", ")}") if !invalid_scopes.empty?

          # Create the role creation request event
          event = Roles::Creation::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: command.aggregate_id,
            command_handler: self.class.to_s,
            name: command.name,
            permissions: command.permissions,
            scope_id: command.scope_id,
            scopes: scopes
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
