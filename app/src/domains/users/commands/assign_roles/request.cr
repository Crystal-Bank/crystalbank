module CrystalBank::Domains::Users
  module AssignRoles
    module Commands
      class Request < ES::Command
        def call(aggregate_id : UUID, r : Users::Api::Requests::AssignRolesRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # Check if provided roles do exist
          repository = Users::Repositories::Roles.new
          r.role_ids.each { |role_id| repository.exists!(role_id) }

          # Build the user aggregate
          aggregate = Users::Aggregate.new(aggregate_id)
          aggregate.hydrate

          # Check if roles are already assigned to aggregate
          common_roles = r.role_ids & aggregate.state.role_ids
          if !common_roles.empty?
            raise CrystalBank::Exception::InvalidArgument.new("The roles [#{common_roles.map(&.to_s).join(", ")}] are already assigned to the user")
          end

          # Calculate the next aggregate version
          next_version = aggregate.state.next_version

          # Create the assign roles request event
          event = Users::AssignRoles::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            aggregate_id: aggregate_id,
            aggregate_version: next_version,
            role_ids: r.role_ids,
            scope_id: scope,
          )

          # Append event to event store
          @event_store.append(event)

          # Return the aggregate ID of the newly created user aggregate
          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
