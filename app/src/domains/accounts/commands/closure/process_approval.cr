module CrystalBank::Domains::Accounts
  module Closure
    module Commands
      class ProcessApproval < ES::Command
        def call
          approval = Approvals::Aggregate.new(@aggregate_id.as(UUID))
          approval.hydrate

          return unless approval.state.source_aggregate_type == "AccountClosure"

          closure_request_id = approval.state.source_aggregate_id.as(UUID)

          closure_request = ::Accounts::Closure::Aggregate.new(closure_request_id)
          closure_request.hydrate

          return if closure_request.state.completed

          account_id = closure_request.state.account_id.as(UUID)

          account = ::Accounts::Aggregate.new(account_id)
          account.hydrate

          accepted_event = ::Accounts::Closure::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: account_id,
            aggregate_version: account.state.next_version,
            command_handler: self.class.to_s
          )
          @event_store.append(accepted_event)

          completed_event = ::Accounts::Closure::Closure::Events::Completed.new(
            actor_id: nil,
            aggregate_id: closure_request_id,
            aggregate_version: closure_request.state.next_version,
            command_handler: self.class.to_s
          )
          @event_store.append(completed_event)
        end
      end
    end
  end
end
