module CrystalBank::Domains::Ledger::Transactions
  module Request
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)

          aggregate = Ledger::Transactions::Aggregate.new(aggregate_id)
          aggregate.hydrate

          next_version = aggregate.state.next_version

          event = Ledger::Transactions::Request::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: aggregate_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s
          )

          @event_store.append(event)
        end
      end
    end
  end
end
