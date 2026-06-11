module CrystalBank::Domains::Ledger::Transactions
  module Request
    module Commands
      class Request < ES::Command
        def call(r : Ledger::Transactions::Api::Requests::TransactionRequest, c : CrystalBank::Api::Context) : {transaction_id: UUID, approval_id: UUID}
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
            actor_id: actor,
            command_handler: self.class.to_s,
            currency: r.currency,
            entries_json: entries_json,
            posting_date: posting_date,
            value_date: value_date,
            remittance_information: r.remittance_information,
            payment_type: metadata.try(&.payment_type),
            external_ref: metadata.try(&.external_ref),
            channel: metadata.try(&.channel),
            scope_id: scope,
          )

          @event_store.append(event)

          transaction_id = UUID.new(event.header.aggregate_id.to_s)

          # Build a human-readable snapshot so approvers have full context
          currency_str = r.currency.to_s.upcase
          amount_formatted = "%.2f %s" % [debit_total / 100.0, currency_str]
          summary = if (ref = r.remittance_information) && !ref.empty?
                      "#{amount_formatted} · #{ref}"
                    else
                      "#{amount_formatted} · #{entries.size} entries"
                    end

          approval_fields = [
            Approvals::ApprovalSubject::Field.new("Currency", currency_str),
            Approvals::ApprovalSubject::Field.new("Total Amount", amount_formatted),
            Approvals::ApprovalSubject::Field.new("Entries", entries.size.to_s),
            Approvals::ApprovalSubject::Field.new("Posting Date", r.posting_date),
            Approvals::ApprovalSubject::Field.new("Value Date", r.value_date),
          ] of Approvals::ApprovalSubject::Field

          if (ref = r.remittance_information) && !ref.empty?
            approval_fields << Approvals::ApprovalSubject::Field.new("Remittance", ref)
          end

          entries_data.each_with_index do |entry, i|
            account_name = found_by_id[entry.account_id]?.try(&.name) || entry.account_id.to_s
            entry_amount = "%.2f %s" % [entry.amount / 100.0, currency_str]
            label = "Entry #{i + 1} (#{entry.direction.capitalize})"
            approval_fields << Approvals::ApprovalSubject::Field.new(label, "#{account_name} · #{entry_amount} · #{entry.entry_type}")
          end

          approval_subject = Approvals::ApprovalSubject.new(
            title: "Ledger Transaction",
            summary: summary,
            fields: approval_fields,
          )

          approval_id = Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "LedgerTransaction",
            source_aggregate_id: transaction_id,
            scope_id: scope,
            required_approvals: ["write_ledger_transactions_request_approval"],
            actor_id: actor,
            subject: approval_subject,
          )

          {transaction_id: transaction_id, approval_id: approval_id}
        end
      end
    end
  end
end
