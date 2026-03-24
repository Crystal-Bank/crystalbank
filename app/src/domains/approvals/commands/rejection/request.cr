module CrystalBank::Domains::Approvals
  module Rejection
    module Commands
      class Request < ES::Command
        def call(approval_id : UUID, user_id : UUID, user_roles : Array(UUID), comment : String = "") : Nil
          # Hydrate the approval aggregate
          aggregate = Approvals::Aggregate.new(approval_id)
          aggregate.hydrate

          state = aggregate.state

          # Check if the approval process is already completed
          raise CrystalBank::Exception::InvalidArgument.new("Approval process is already completed") if state.completed

          # Check if the approval process is already rejected
          raise CrystalBank::Exception::InvalidArgument.new("Approval process is already rejected") if state.rejected

          # The actor can reject if they are the requestor OR if they have a required approval permission.
          # This is the key distinction from collection: the requestor IS allowed to reject their own request.
          is_requestor = state.requestor_id == user_id
          unless is_requestor
            user_permissions = find_matching_permissions(state.required_approvals, user_roles)
            raise CrystalBank::Exception::InvalidArgument.new("User does not have permission to reject this approval") if user_permissions.empty?
          end

          next_version = state.next_version

          rejected_event = Approvals::Rejection::Events::Rejected.new(
            actor_id: user_id,
            aggregate_id: approval_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
            user_id: user_id,
            comment: comment
          )
          @event_store.append(rejected_event)
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
      end
    end
  end
end
