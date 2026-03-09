module CrystalBank::Domains::Ledger::Transactions
  module Request
    module Commands
      class Request < ES::Command
        def call(r : Ledger::Transactions::Api::Requests::TransactionRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          entries = r.entries

          # Check minimum entries
          raise CrystalBank::Exception::InvalidArgument.new("At least two entries are required") if entries.size < 2

          # Check all amounts are positive
          entries.each do |entry|
            raise CrystalBank::Exception::InvalidArgument.new("Entry amount must be greater than zero") if entry.amount <= 0
          end

          # Check ledger balance: sum of DEBITs must equal sum of CREDITs
          debit_total = entries.select { |e| e.direction.debit? }.sum(&.amount)
          credit_total = entries.select { |e| e.direction.credit? }.sum(&.amount)
          raise CrystalBank::Exception::InvalidArgument.new(
            "Ledger entries do not balance: debit total #{debit_total} does not equal credit total #{credit_total}"
          ) unless debit_total == credit_total

          # Validate all accounts exist in the projection in one query (presence == open,
          # rows are only inserted on account.opening.accepted)
          account_ids = entries.map(&.account_id).uniq!
          found_ids = Accounts::Queries::Accounts.new.find_all(account_ids).map(&.id).to_set
          account_ids.each do |id|
            raise CrystalBank::Exception::InvalidArgument.new(
              "Account '#{id}' is not open"
            ) unless found_ids.includes?(id)
          end

          # Serialize entries to JSON for the event
          entries_data = entries.map do |e|
            Ledger::Transactions::Aggregate::Entry.new(
              account_id: e.account_id,
              direction: e.direction.to_s,
              amount: e.amount,
              entry_type: e.entry_type.to_s,
            )
          end
          entries_json = entries_data.to_json

          metadata = r.metadata

          event = Ledger::Transactions::Request::Events::Requested.new(
            actor_id: actor,
            currency: r.currency.to_s,
            entries_json: entries_json,
            posting_date: r.posting_date,
            value_date: r.value_date,
            remittance_information: r.remittance_information,
            payment_type: metadata.try(&.payment_type),
            external_ref: metadata.try(&.external_ref),
            channel: metadata.try(&.channel),
            internal_note: metadata.try(&.internal_note),
            scope_id: scope,
          )

          @event_store.append(event)

          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
