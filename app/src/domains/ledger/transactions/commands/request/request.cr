module CrystalBank::Domains::Ledger::Transactions
  module Request
    module Commands
      struct Request < ES::Command
        getter r : Ledger::Transactions::Api::Requests::TransactionRequest
        getter actor_id : UUID
        getter scope_id : UUID

        def initialize(@aggregate_id : UUID, @r, @actor_id, @scope_id)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request)
          r = command.r
          entries = r.entries

          # Check minimum entries
          raise CrystalBank::Exception::InvalidArgument.new("At least two entries are required") if entries.size < 2

          # Check all amounts are positive
          entries.each do |entry|
            raise CrystalBank::Exception::InvalidArgument.new("Entry amount must be greater than zero") if entry.amount <= 0
          end

          # Check date formats
          posting_date = Time.utc
          begin
            posting_date = Time::Format::ISO_8601_DATE.parse(r.posting_date) # Validate date format
          rescue
            raise CrystalBank::Exception::InvalidArgument.new("Invalid posting_date format, expected YYYY-MM-DD")
          end

          value_date = Time.utc
          begin
            value_date = Time::Format::ISO_8601_DATE.parse(r.value_date) # Validate date format
          rescue
            raise CrystalBank::Exception::InvalidArgument.new("Invalid value_date format, expected YYYY-MM-DD")
          end

          # Check ledger balance: sum of DEBITs must equal sum of CREDITs
          debit_total = entries.select { |e| e.direction.debit? }.sum(&.amount)
          credit_total = entries.select { |e| e.direction.credit? }.sum(&.amount)
          raise CrystalBank::Exception::InvalidArgument.new(
            "Ledger entries do not balance: debit total #{debit_total} does not equal credit total #{credit_total}"
          ) unless debit_total == credit_total

          # Validate all accounts exist in the projection and are active (presence + status == open,
          # rows are inserted on account.opening.requested and set to active on account.opening.accepted)
          account_ids = entries.map(&.account_id).uniq!
          found_accounts = Accounts::Queries::Accounts.new.find_all(account_ids)
          found_by_id = found_accounts.to_h { |a| {a.id, a} }
          account_ids.each do |id|
            account = found_by_id[id]?
            raise CrystalBank::Exception::InvalidArgument.new(
              "Account '#{id}' is not open"
            ) unless account && account.status == "active"
            raise CrystalBank::Exception::InvalidArgument.new(
              "Account '#{id}' does not support currency #{r.currency}"
            ) unless account.currencies.includes?(r.currency)
          end

          # Serialize entries to JSON for the event
          entries_data = entries.map do |e|
            Ledger::Transactions::Aggregate::Entry.new(
              id: UUID.v7,
              account_id: e.account_id,
              direction: e.direction.to_s,
              amount: e.amount,
              entry_type: e.entry_type.to_s,
            )
          end
          entries_json = entries_data.to_json

          metadata = r.metadata

          event = Ledger::Transactions::Request::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: command.aggregate_id,
            command_handler: self.class.to_s,
            currency: r.currency,
            entries_json: entries_json,
            posting_date: posting_date,
            value_date: value_date,
            remittance_information: r.remittance_information,
            payment_type: nil,
            external_ref: metadata.try(&.external_ref),
            channel: nil,
            scope_id: command.scope_id,
          )

          @event_store.append(event)
        end
      end
    end
  end
end
