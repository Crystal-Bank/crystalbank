module CrystalBank::Domains::Approvals
  module Finalization
    module Commands
      # Subscribed to Approvals::Submission::Events::AllApproved.
      #
      # Reads the Approval aggregate to discover which domain action was waiting
      # and emits its final Accepted event so downstream projections can react.
      # Adding a new approvable action only requires a new `when` branch here.
      class Finalize < ES::Command
        def call
          approval_aggregate_id = @aggregate_id.as(UUID)

          approval_aggregate = CrystalBank::Domains::Approvals::Aggregate.new(approval_aggregate_id)
          approval_aggregate.hydrate

          reference_type = approval_aggregate.state.reference_type.not_nil!
          reference_aggregate_id = approval_aggregate.state.reference_aggregate_id.not_nil!

          case reference_type
          when "accounts.opening"
            finalize_account_opening(reference_aggregate_id)
          else
            raise "Unknown approval reference_type: #{reference_type}"
          end
        end

        private def finalize_account_opening(aggregate_id : UUID)
          account_aggregate = CrystalBank::Domains::Accounts::Aggregate.new(aggregate_id)
          account_aggregate.hydrate

          event = CrystalBank::Domains::Accounts::Opening::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: aggregate_id,
            aggregate_version: account_aggregate.state.next_version,
            command_handler: self.class.to_s
          )

          @event_store.append(event)
        end
      end
    end
  end
end
