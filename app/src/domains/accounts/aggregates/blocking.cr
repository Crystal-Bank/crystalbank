module CrystalBank::Domains::Accounts
  module Aggregates
    module Concerns
      module Blocking
        # Apply 'Accounts::Blocking::Events::Applied' to the aggregate state
        def apply(event : Accounts::Blocking::Events::Applied)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Accounts::Blocking::Events::Applied::Body)
          @state.active_blocks << body.block_type unless @state.active_blocks.includes?(body.block_type)
        end

        # Apply 'Accounts::Blocking::Events::Removed' to the aggregate state
        def apply(event : Accounts::Blocking::Events::Removed)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Accounts::Blocking::Events::Removed::Body)
          @state.active_blocks.delete(body.block_type)
        end
      end
    end
  end
end
