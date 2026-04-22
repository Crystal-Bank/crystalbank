module CrystalBank::Domains::Users
  module RemoveRoles
    module Commands
      class Request < ES::Command
        def call(aggregate_id : UUID, r : Users::Api::Requests::RemoveRolesRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # Build the user aggregate
          aggregate = Users::Aggregate.new(aggregate_id)
          aggregate.hydrate

          # Check if provided roles are actually assigned to the user
          missing_roles = r.role_ids - aggregate.state.role_ids
          if !missing_roles.empty?
            raise CrystalBank::Exception::InvalidArgument.new("The roles [#{missing_roles.map(&.to_s).join(", ")}] are not assigned to the user")
          end

          # Calculate the next aggregate version
          next_version = aggregate.state.next_version

          # Create the remove roles request event
          event = Users::RemoveRoles::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            aggregate_id: aggregate_id,
            aggregate_version: next_version,
            role_ids: r.role_ids,
            scope_id: scope,
          )

          # Append event to event store
          @event_store.append(event)

          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
