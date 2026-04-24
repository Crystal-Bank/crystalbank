module CrystalBank::Domains::Users
  module RemoveRoles
    module Commands
      class Request < ES::Command
        def call(aggregate_id : UUID, r : Users::Api::Requests::RemoveRolesRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # Build the user aggregate and validate role assignments
          user = Users::Aggregate.new(aggregate_id)
          user.hydrate

          missing_roles = r.role_ids - user.state.role_ids
          if !missing_roles.empty?
            raise CrystalBank::Exception::InvalidArgument.new("The roles [#{missing_roles.map(&.to_s).join(", ")}] are not assigned to the user")
          end

          # Create a new request aggregate (auto-generates its own UUID)
          event = Users::RemoveRoles::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            user_id: aggregate_id,
            role_ids: r.role_ids,
            scope_id: scope,
          )

          @event_store.append(event)

          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
