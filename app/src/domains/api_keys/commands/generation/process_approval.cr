module CrystalBank::Domains::ApiKeys
  module Generation
    module Commands
      class ProcessApproval < ES::Command
        def call
          approval_aggregate_id = @aggregate_id.as(UUID)

          # Hydrate the approval aggregate to get source info
          approval = Approvals::Aggregate.new(approval_aggregate_id)
          approval.hydrate

          # Only process if this approval is for an ApiKey
          return unless approval.state.source_aggregate_type == "ApiKey"

          api_key_id = approval.state.source_aggregate_id.as(UUID)

          # Build the api key aggregate
          api_key = ApiKeys::Aggregate.new(api_key_id)
          api_key.hydrate

          # Calculate the next aggregate version
          next_version = api_key.state.next_version

          # Create the api key generation acceptance event
          event = ApiKeys::Generation::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: api_key_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
