module CrystalBank::Domains::Customers
  module Onboarding
    module Commands
      class ProcessApproval < ES::Command
        def call
          approval_aggregate_id = @aggregate_id.as(UUID)

          # Hydrate the approval aggregate to get source info
          approval = Approvals::Aggregate.new(approval_aggregate_id)
          approval.hydrate

          # Only process if this approval is for a Customer
          return unless approval.state.source_aggregate_type == "Customer"

          customer_id = approval.state.source_aggregate_id.as(UUID)

          # Build the customer aggregate
          customer = Customers::Aggregate.new(customer_id)
          customer.hydrate

          # Calculate the next aggregate version
          next_version = customer.state.next_version

          # Create the customer onboarding acceptance event
          event = Customers::Onboarding::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: customer_id,
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
