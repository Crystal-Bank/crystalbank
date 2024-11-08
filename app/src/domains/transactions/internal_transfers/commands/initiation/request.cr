module CrystalBank::Domains::Transactions::InternalTransfers
  module Commands
    class Request < ES::Command
      def call(r : Transactions::InternalTransfers::Api::Requests::InitiationRequest) : UUID
        # TODO: Replace with actor from context
        dummy_actor = UUID.new("00000000-0000-0000-0000-000000000000")

        creditor_account_id = r.creditor_account_id
        currency = r.currency
        debtor_account_id = r.debtor_account_id

        # Check if accounts are the same
        raise CrystalBank::Exception::InvalidArgument.new("Debtor and creditor account cannot be the same") if creditor_account_id == debtor_account_id

        # Check debtor account state
        debtor_account_aggr = CrystalBank::Domains::Accounts::Aggregate.new(debtor_account_id)
        debtor_account_aggr.hydrate

        raise CrystalBank::Exception::InvalidArgument.new("Debtor account is not open") unless debtor_account_aggr.state.open
        raise CrystalBank::Exception::InvalidArgument.new(
          "The requested currency '#{currency.to_s}' is not supported by the debtor account. Available currencies are: '#{debtor_account_aggr.state.supported_currencies.join(", ")}'"
        ) unless debtor_account_aggr.state.supported_currencies.includes?(currency)

        # Check creditor account state
        creditor_account_aggr = CrystalBank::Domains::Accounts::Aggregate.new(creditor_account_id)
        creditor_account_aggr.hydrate

        raise CrystalBank::Exception::InvalidArgument.new("Creditor account is not open") unless creditor_account_aggr.state.open
        raise CrystalBank::Exception::InvalidArgument.new(
          "The requested currency '#{currency.to_s}' is not supported by the creditor account. Available currencies are: '#{creditor_account_aggr.state.supported_currencies.join(", ")}'"
        ) unless creditor_account_aggr.state.supported_currencies.includes?(currency)

        # Create the account creation request event
        event = Transactions::InternalTransfers::Initiation::Events::Requested.new(
          actor_id: dummy_actor,
          command_handler: self.class.to_s,
          currency: r.currency,
          amount: r.amount,
          debtor_account_id: debtor_account_id,
          creditor_account_id: creditor_account_id
        )

        # Append event to event store
        @event_store.append(event)

        # Return the aggregate ID of the newly created internal transfer aggregate
        UUID.new(event.header.aggregate_id.to_s)
      end
    end
  end
end
