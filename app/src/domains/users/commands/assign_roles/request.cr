module CrystalBank::Domains::Users
  module AssignRoles
    module Commands
      class Request < ES::Command
        def call(r : Users::Api::Requests::AssignRolesRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # Create the assign roles request event
          event = Users::AssignRoles::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
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
