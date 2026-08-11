module CrystalBank::Domains::Scopes
  module NameChange
    module Commands
      struct Request < ES::Command
        getter target_scope_id : UUID
        getter name : String
        getter actor_id : UUID
        getter scope_id : UUID

        def initialize(@aggregate_id : UUID, @target_scope_id, @name, @actor_id, @scope_id)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request)
          # Validate the scope exists and is active
          target = Scopes::Queries::Scopes.new.get(command.target_scope_id)
          raise CrystalBank::Exception::InvalidArgument.new("Scope '#{command.target_scope_id}' not found") unless target
          raise CrystalBank::Exception::InvalidArgument.new("Scope '#{command.target_scope_id}' is not active") unless target.status == "active"

          # Guard against no-op renames
          if command.name == target.name
            raise CrystalBank::Exception::InvalidArgument.new("Name is unchanged — the submitted name is identical to the scope's current name")
          end

          name_change_request_id = command.aggregate_id
          event = Scopes::NameChange::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: name_change_request_id,
            command_handler: self.class.to_s,
            scope_id: command.target_scope_id,
            name: command.name
          )
          @event_store.append(event)

          approval_subject = Approvals::ApprovalSubject.new(
            title: "Scope Rename",
            summary: "\"#{target.name}\" → \"#{command.name}\"",
            fields: [
              Approvals::ApprovalSubject::Field.new("From", target.name),
              Approvals::ApprovalSubject::Field.new("To", command.name),
            ] of Approvals::ApprovalSubject::Field
          )

          approval_id = UUID.v7
          Approvals::Creation::Commands::RequestHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Approvals::Creation::Commands::Request.new(
              aggregate_id: approval_id,
              source_aggregate_type: "ScopeNameChange",
              source_aggregate_id: name_change_request_id,
              scope_id: command.scope_id,
              required_approvals: ["write_scopes_name_change_approval"],
              actor_id: command.actor_id,
              subject: approval_subject,
            )
          )

          {name_change_request_id: name_change_request_id, approval_id: approval_id}
        end
      end
    end
  end
end
