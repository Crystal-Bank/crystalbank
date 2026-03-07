module CrystalBank::Domains::Approvals
  module Creation
    module Commands
      class Request < ES::Command
        def call(
          source_aggregate_type : String,
          source_aggregate_id : UUID,
          scope_id : UUID,
          required_approvals : Array(String),
          actor_id : UUID?,
          requestor_id : UUID? = nil,
        ) : UUID
          raise CrystalBank::Exception::InvalidArgument.new("Required approvals cannot be empty") if required_approvals.empty?

          # Create the approval creation request event
          event = Approvals::Creation::Events::Requested.new(
            actor_id: actor_id,
            command_handler: self.class.to_s,
            scope_id: scope_id,
            source_aggregate_type: source_aggregate_type,
            source_aggregate_id: source_aggregate_id,
            required_approvals: required_approvals,
            requestor_id: requestor_id
          )

          # Append event to event store
          @event_store.append(event)

          # Return the aggregate ID of the newly created approval aggregate
          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
