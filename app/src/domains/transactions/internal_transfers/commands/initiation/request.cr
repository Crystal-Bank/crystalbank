module CrystalBank::Domains::Transactions::InternalTransfers
  module Initiation
    module Commands
      class Request < ES::Command
        def call(r : Transactions::InternalTransfers::Api::Requests::InitiationRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          amount = r.amount
          creditor_account_id = r.creditor_account_id
          currency = r.currency
          debtor_account_id = r.debtor_account_id

          # Check if transfer amount is valid
          raise CrystalBank::Exception::InvalidArgument.new("Transfer amount must be greater than zero") if amount <= 0

          # Check if accounts are the same
          raise CrystalBank::Exception::InvalidArgument.new("Debtor and creditor account cannot be the same") if creditor_account_id == debtor_account_id

          # Check debtor account state
          debtor_account_aggr = CrystalBank::Domains::Accounts::Aggregate.new(debtor_account_id)
          debtor_account_aggr.hydrate

          raise CrystalBank::Exception::InvalidArgument.new("Debtor account is not open") unless debtor_account_aggr.state.open
          raise CrystalBank::Exception::InvalidArgument.new(
            "The requested currency '#{currency.to_s.downcase}' is not supported by the debtor account. Available currencies are: '#{debtor_account_aggr.state.supported_currencies.join(", ")}'"
          ) unless debtor_account_aggr.state.supported_currencies.includes?(currency)

          # Check creditor account state
          creditor_account_aggr = CrystalBank::Domains::Accounts::Aggregate.new(creditor_account_id)
          creditor_account_aggr.hydrate

          raise CrystalBank::Exception::InvalidArgument.new("Creditor account is not open") unless creditor_account_aggr.state.open
          raise CrystalBank::Exception::InvalidArgument.new(
            "The requested currency '#{currency.to_s.downcase}' is not supported by the creditor account. Available currencies are: '#{creditor_account_aggr.state.supported_currencies.join(", ")}'"
          ) unless creditor_account_aggr.state.supported_currencies.includes?(currency)

          # Create the account creation request event
          event = Transactions::InternalTransfers::Initiation::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            currency: currency,
            amount: amount,
            debtor_account_id: debtor_account_id,
            creditor_account_id: creditor_account_id,
            remittance_information: r.remittance_information,
            scope_id: scope,
          )

          # Append event to event store
          @event_store.append(event)

          # Return the aggregate ID of the newly created internal transfer aggregate
          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
