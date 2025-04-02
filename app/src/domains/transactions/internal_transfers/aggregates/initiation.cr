module CrystalBank::Domains::Transactions::InternalTransfers
  module Aggregates
    module Concerns
      module Initiation
        # Apply 'Transactions::InternalTransfers::Initiation::Events::Accepted' to the aggregate state
        def apply(event : Transactions::InternalTransfers::Initiation::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)
        end

        # Apply 'Transactions::InternalTransfers::Initiation::Events::Requested' to the aggregate state
        def apply(event : Transactions::InternalTransfers::Initiation::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Transactions::InternalTransfers::Initiation::Events::Requested::Body)

          @state.amount = body.amount
          @state.currency = body.currency
          @state.debtor_account_id = body.debtor_account_id
          @state.creditor_account_id = body.creditor_account_id
          @state.remittance_information = body.remittance_information
          @state.scope_id = body.scope_id
        end
      end
    end
  end
end
