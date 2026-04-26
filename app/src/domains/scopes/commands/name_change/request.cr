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

          # Pending guard: at most one rename request may be in flight per scope
          has_pending = ES::Config.projection_database.query_one(
            %(SELECT EXISTS (SELECT 1 FROM "projections"."scopes_name_changes" WHERE scope_id = $1 AND status = 'pending_approval')),
            r.scope_id,
            as: Bool
          )
          if has_pending
            raise CrystalBank::Exception::InvalidArgument.new("Scope '#{r.scope_id}' already has a pending name change request")
          end

          event = Scopes::NameChange::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            scope_id: r.scope_id,
            name: r.name
          )
          @event_store.append(event)

          name_change_request_id = UUID.new(event.header.aggregate_id.to_s)

          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "ScopeNameChange",
            source_aggregate_id: name_change_request_id,
            scope_id: scope,
            required_approvals: ["write_scopes_name_change_approval"],
            actor_id: actor
          )

          name_change_request_id
        end
      end
    end
  end
end
