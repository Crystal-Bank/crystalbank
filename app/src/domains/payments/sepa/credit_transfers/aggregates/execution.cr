module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Aggregates
    module Concerns
      module Execution
        def apply(event : Payments::Sepa::CreditTransfers::Execution::Events::Executed)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Payments::Sepa::CreditTransfers::Execution::Events::Executed::Body)

          @state.ledger_transaction_id = body.ledger_transaction_id
          @state.status = "executed"
        end
      end
    end
  end
end
