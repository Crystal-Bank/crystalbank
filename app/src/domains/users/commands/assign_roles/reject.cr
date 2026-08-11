module CrystalBank::Domains::Users
  module AssignRoles
    module Commands
      struct Reject < ES::Command
      end

      class RejectHandler < ES::CommandHandler(Reject)
        def handle(command : Reject)
          request_id = command.aggregate_id

          request = Users::AssignRolesRequest::Aggregate.new(request_id, event_store: @event_store, event_handlers: @event_handlers)
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
