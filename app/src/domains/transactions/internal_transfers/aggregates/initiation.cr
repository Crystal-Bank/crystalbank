module CrystalBank::Domains::Transactions::InternalTransfers
  module Aggregates
    module Concerns
      module Initiation
        # Apply 'Accounts::Opening::Events::Accepted' to the aggregate state
        def apply(event : Transactions::InternalTransfers::Initiation::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Transactions::InternalTransfers::Initiation::Events::Requested::Body)
        end
      end
    end
  end
end
