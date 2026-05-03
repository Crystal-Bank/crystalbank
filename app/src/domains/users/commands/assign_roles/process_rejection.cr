module CrystalBank::Domains::Users
  module AssignRoles
    module Commands
      class ProcessRejection < ES::Command
        def call
          approval_aggregate_id = @aggregate_id.as(UUID)

          approval = Approvals::Aggregate.new(approval_aggregate_id)
          approval.hydrate

          return unless approval.state.source_aggregate_type == "UserRolesAssignment"

          request_id = approval.state.source_aggregate_id.as(UUID)

          request = Users::AssignRolesRequest::Aggregate.new(request_id)
          request.hydrate

          return if request.state.completed
          return if request.state.rejected

          rejected_event = Users::AssignRoles::Events::Rejected.new(
            actor_id: nil,
            aggregate_id: request_id,
            aggregate_version: request.state.next_version,
            command_handler: self.class.to_s
          )
          @event_store.append(rejected_event)
        end
      end
    end
  end
end
