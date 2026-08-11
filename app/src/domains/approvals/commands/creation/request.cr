module CrystalBank::Domains::Approvals
  module Creation
    module Commands
      struct Request < ES::Command
        getter source_aggregate_type : String
        getter source_aggregate_id : UUID
        getter scope_id : UUID
        getter required_approvals : Array(String)
        getter actor_id : UUID?
        getter subject : CrystalBank::Domains::Approvals::ApprovalSubject?

        def initialize(
          @aggregate_id : UUID,
          @source_aggregate_type,
          @source_aggregate_id,
          @scope_id,
          @required_approvals,
          @actor_id,
          @subject = nil,
        )
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request)
          raise CrystalBank::Exception::InvalidArgument.new("Required approvals cannot be empty") if command.required_approvals.empty?

          # Create the approval creation request event
          event = Approvals::Creation::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: command.aggregate_id,
            command_handler: self.class.to_s,
            scope_id: command.scope_id,
            source_aggregate_type: command.source_aggregate_type,
            source_aggregate_id: command.source_aggregate_id,
            required_approvals: command.required_approvals,
            subject: command.subject
          )

          @event_store.append(event)
        end
      end
    end
  end
end
