module CrystalBank::Domains::Approvals
  module Collection
    module Commands
      class Request < ES::Command
        def call(approval_id : UUID, user_id : UUID, user_roles : Array(UUID)) : Nil
          # Hydrate the approval aggregate
          aggregate = Approvals::Aggregate.new(approval_id)
          aggregate.hydrate

          state = aggregate.state

          # Check if the approval process is already completed
          raise CrystalBank::Exception::InvalidArgument.new("Approval process is already completed") if state.completed

          # Check if the user is the requestor
          raise CrystalBank::Exception::InvalidArgument.new("Requestor cannot approve their own request") if state.requestor_id == user_id

          # Check if the user has already provided an approval
          already_approved = state.collected_approvals.any? { |ca| ca.user_id == user_id }
          raise CrystalBank::Exception::InvalidArgument.new("User has already provided an approval for this process") if already_approved

          # Determine which required approvals are still pending
          collected_permissions = state.collected_approvals.map(&.permission)
          pending_approvals = state.required_approvals.reject { |ra| collected_permissions.includes?(ra) }

          # Find the first pending approval that the user can satisfy
          matched_permission = find_matching_permission(pending_approvals, user_roles)
          raise CrystalBank::Exception::InvalidArgument.new("User does not have any required approval permission") unless matched_permission

          # Calculate the next aggregate version
          next_version = state.next_version

          # Append the collected event
          collected_event = Approvals::Collection::Events::Collected.new(
            actor_id: user_id,
            aggregate_id: approval_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
            user_id: user_id,
            permission: matched_permission
          )
          @event_store.append(collected_event)

          # Check if all required approvals are now satisfied
          newly_collected = collected_permissions + [matched_permission]
          all_satisfied = state.required_approvals.all? { |ra| newly_collected.includes?(ra) }

          if all_satisfied
            completed_event = Approvals::Collection::Events::Completed.new(
              actor_id: user_id,
              aggregate_id: approval_id,
              aggregate_version: next_version + 1,
              command_handler: self.class.to_s
            )
            @event_store.append(completed_event)
          end
        end

        private def find_matching_permission(pending_approvals : Array(String), user_roles : Array(UUID)) : String?
          roles_permissions = Roles::Queries::RolesPermissions.new

          pending_approvals.each do |required_permission|
            begin
              permission = CrystalBank::Permissions.parse(required_permission)
              available_scopes = roles_permissions.available_scopes(user_roles, permission)
              return required_permission unless available_scopes.empty?
            rescue ArgumentError
              # Permission string doesn't match enum — skip
              next
            end
          end

          nil
        end
      end
    end
  end
end
