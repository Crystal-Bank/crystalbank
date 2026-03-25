module CrystalBank::Domains::Approvals
  module Collection
    module Commands
      class Request < ES::Command
        def call(approval_id : UUID, r : CrystalBank::Domains::Approvals::Api::Requests::CollectRequest, c : CrystalBank::Api::Context) : Nil
          actor_id = c.user_id
          scope = c.scope
          roles = c.roles
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # Hydrate the approval aggregate
          aggregate = Approvals::Aggregate.new(approval_id)
          aggregate.hydrate

          state = aggregate.state

          # Check if the approval process is already completed
          raise CrystalBank::Exception::InvalidArgument.new("Approval process is already completed") if state.completed

          # Check if the approval process is already rejected
          raise CrystalBank::Exception::InvalidArgument.new("Approval process is already rejected") if state.rejected

          # Check if the user is the requestor
          raise CrystalBank::Exception::InvalidArgument.new("Requestor cannot approve their own request") if state.requestor_id == actor_id

          # Check if the user has already provided an approval
          already_approved = state.collected_approvals.any? { |ca| ca.user_id == actor_id }
          raise CrystalBank::Exception::InvalidArgument.new("User has already provided an approval for this process") if already_approved

          # Find all required permissions this user can satisfy
          user_permissions = find_matching_permissions(state.required_approvals, roles)
          raise CrystalBank::Exception::InvalidArgument.new("User does not have any required approval permission") if user_permissions.empty?

          # Build the full set of collected permissions for the completion check
          all_collected = state.collected_approvals.map(&.permissions) + [user_permissions]

          # Calculate the next aggregate version
          next_version = state.next_version

          # Append the collected event
          collected_event = Approvals::Collection::Events::Collected.new(
            actor_id: actor_id,
            aggregate_id: approval_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
            user_id: actor_id,
            permissions: user_permissions,
            comment: r.comment
          )
          @event_store.append(collected_event)

          # Check if all required approvals are now satisfied with enough distinct users
          if all_collected.size >= state.required_approvals.size && can_satisfy?(state.required_approvals, all_collected)
            completed_event = Approvals::Collection::Events::Completed.new(
              actor_id: actor_id,
              aggregate_id: approval_id,
              aggregate_version: next_version + 1,
              command_handler: self.class.to_s
            )
            @event_store.append(completed_event)
          end
        end

        private def find_matching_permissions(required_approvals : Array(String), user_roles : Array(UUID)) : Array(String)
          roles_permissions = Roles::Queries::RolesPermissions.new
          matched = Array(String).new

          required_approvals.each do |required_permission|
            begin
              permission = CrystalBank::Permissions.parse(required_permission)
              available_scopes = roles_permissions.available_scopes(user_roles, permission)
              matched << required_permission unless available_scopes.empty?
            rescue ArgumentError
              next
            end
          end

          matched
        end

        # Bipartite matching: can each required permission be assigned to a distinct user?
        private def can_satisfy?(required : Array(String), collected_permissions : Array(Array(String))) : Bool
          assignment = Array(Int32).new(required.size, -1)
          match(required, collected_permissions, assignment, 0)
        end

        private def match(required : Array(String), collected : Array(Array(String)), assignment : Array(Int32), idx : Int32) : Bool
          return true if idx == required.size

          perm = required[idx]
          collected.each_with_index do |user_perms, user_idx|
            next if assignment.includes?(user_idx)
            next unless user_perms.includes?(perm)

            assignment[idx] = user_idx
            return true if match(required, collected, assignment, idx + 1)
            assignment[idx] = -1
          end

          false
        end
      end
    end
  end
end
