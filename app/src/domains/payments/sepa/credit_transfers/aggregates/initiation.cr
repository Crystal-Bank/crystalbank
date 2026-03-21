module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Aggregates
    module Concerns
      module Initiation
        def apply(event : Payments::Sepa::CreditTransfers::Initiation::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Payments::Sepa::CreditTransfers::Initiation::Events::Requested::Body)

          @state.end_to_end_id = body.end_to_end_id
          @state.debtor_account_id = body.debtor_account_id
          @state.settlement_account_id = body.settlement_account_id
          @state.creditor_iban = body.creditor_iban
          @state.creditor_name = body.creditor_name
          @state.creditor_bic = body.creditor_bic
          @state.amount = body.amount
          @state.execution_date = body.execution_date
          @state.remittance_information = body.remittance_information
          @state.scope_id = body.scope_id
          @state.status = "pending"
        end
      end
    end
  end
end
