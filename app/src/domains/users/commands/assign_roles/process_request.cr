module CrystalBank::Domains::Users
  module AssignRoles
    module Commands
      class ProcessRequest < ES::Command
        def call
          request_aggregate_id = @aggregate_id.as(UUID)

          # Hydrate the request aggregate to get intent
          request = Users::AssignRolesRequest::Aggregate.new(request_aggregate_id)
          request.hydrate

          user_id = request.state.user_id.as(UUID)

          # Hydrate the user aggregate to get scope_id
          user = Users::Aggregate.new(user_id)
          user.hydrate

          scope_id = user.state.scope_id.as(UUID)

          user_name = user.state.name || user.state.email || user_id.to_s
          role_count = request.state.role_ids.size.to_s
          approval_subject = Approvals::ApprovalSubject.new(
            title: "Role Assignment",
            summary: "Assign #{role_count} role(s) to #{user_name}",
            fields: [
              Approvals::ApprovalSubject::Field.new("User", user_name),
              Approvals::ApprovalSubject::Field.new("Roles", role_count),
            ] of Approvals::ApprovalSubject::Field
          )

          # Create an approval workflow for this role assignment
          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "UserRolesAssignment",
            source_aggregate_id: request_aggregate_id,
            scope_id: scope_id,
            required_approvals: [
              "write_users_assign_roles_approval",
            ],
            actor_id: request.state.requestor_id,
            subject: approval_subject,
          )
        end
      end
    end
  end
end
