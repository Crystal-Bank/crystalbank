module CrystalBank::Domains::Scopes
  module NameChange
    module Commands
      class Request < ES::Command
        def call(r : Scopes::Api::Requests::NameChangeRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # Validate the scope exists and is active
          target = Scopes::Queries::Scopes.new.get(r.scope_id)
          raise CrystalBank::Exception::InvalidArgument.new("Scope '#{r.scope_id}' not found") unless target
          raise CrystalBank::Exception::InvalidArgument.new("Scope '#{r.scope_id}' is not active") unless target.status == "active"

          # Guard against no-op renames
          if r.name == target.name
            raise CrystalBank::Exception::InvalidArgument.new("Name is unchanged — the submitted name is identical to the scope's current name")
          end

          event = Scopes::NameChange::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            scope_id: r.scope_id,
            name: r.name
          )
          @event_store.append(event)

          name_change_request_id = UUID.new(event.header.aggregate_id.to_s)

          approval_subject = Approvals::ApprovalSubject.new(
            title: "Scope Rename",
            summary: "\"#{target.name}\" → \"#{r.name}\"",
            fields: [
              Approvals::ApprovalSubject::Field.new("From", target.name),
              Approvals::ApprovalSubject::Field.new("To", r.name),
            ] of Approvals::ApprovalSubject::Field
          )

          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "ScopeNameChange",
            source_aggregate_id: name_change_request_id,
            scope_id: scope,
            required_approvals: ["write_scopes_name_change_approval"],
            actor_id: actor,
            subject: approval_subject,
          )

          name_change_request_id
        end
      end
    end
  end
end
