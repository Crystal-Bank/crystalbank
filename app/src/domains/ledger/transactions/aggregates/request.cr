module CrystalBank::Domains::Ledger::Transactions
  module Aggregates
    module Concerns
      module Request
        # Apply 'Ledger::Transactions::Request::Events::Accepted' to the aggregate state
        def apply(event : Ledger::Transactions::Request::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)
        end

        # Apply 'Ledger::Transactions::Request::Events::Requested' to the aggregate state
        def apply(event : Ledger::Transactions::Request::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Ledger::Transactions::Request::Events::Requested::Body)

          @state.currency = body.currency
          @state.entries = Array(Ledger::Transactions::Aggregate::Entry).from_json(body.entries_json)
          @state.posting_date = body.posting_date
          @state.value_date = body.value_date
          @state.remittance_information = body.remittance_information
          @state.payment_type = body.payment_type
          @state.external_ref = body.external_ref
          @state.channel = body.channel
          @state.scope_id = body.scope_id
        end
      end
    end
  end
end
