module CrystalBank::Domains::Approvals
  module Creation
    module Commands
      # Called internally (not via HTTP) by a domain's ProcessRequest command
      # when it determines that manual approvals are required.
      # Returns the UUID of the newly created Approval aggregate.
      class Request < ES::Command
        def call(
          reference_aggregate_id : UUID,
          reference_type : String,
          scope_id : UUID,
          required_approvals : Array(CrystalBank::Objects::Approval),
          actor_id : UUID
        ) : UUID
          event = Approvals::Creation::Events::Requested.new(
            actor_id: actor_id,
            command_handler: self.class.to_s,
            reference_aggregate_id: reference_aggregate_id,
            reference_type: reference_type,
            scope_id: scope_id,
            required_approvals: required_approvals
          )

          @event_store.append(event)

          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
