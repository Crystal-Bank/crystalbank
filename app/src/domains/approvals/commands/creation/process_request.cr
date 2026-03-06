module CrystalBank::Domains::Approvals
  module Creation
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)

          aggregate = Approvals::Aggregate.new(aggregate_id)
          aggregate.hydrate

          next_version = aggregate.state.next_version

          event = Approvals::Creation::Events::Accepted.new(
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
