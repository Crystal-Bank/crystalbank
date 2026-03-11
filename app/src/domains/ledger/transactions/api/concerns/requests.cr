module CrystalBank::Domains::Ledger::Transactions
  module Api
    module Requests
      struct MetadataRequest
        include JSON::Serializable

        @[JSON::Field(description: "Payment type (e.g. MANUAL_TRANSFER)")]
        getter payment_type : String?

        @[JSON::Field(description: "External reference (e.g. ISO-20022 message ID)")]
        getter external_ref : String?

        @[JSON::Field(description: "Channel through which the transaction was initiated")]
        getter channel : String?
      end

      struct EntryRequest
        include JSON::Serializable

        @[JSON::Field(description: "Account ID for this entry")]
        getter account_id : UUID

        @[JSON::Field(description: "Direction of the entry: DEBIT or CREDIT")]
        getter direction : CrystalBank::Types::LedgerTransactions::Direction

        @[JSON::Field(description: "Amount in the smallest currency unit (e.g. cents)")]
        getter amount : Int64

        @[JSON::Field(description: "Entry type: PRINCIPAL, SETTLEMENT, or TRANSACTION_FEE")]
        getter entry_type : CrystalBank::Types::LedgerTransactions::EntryType
      end

      struct TransactionRequest
        include JSON::Serializable

        @[JSON::Field(description: "ISO 4217 currency code for all entries in this movement")]
        getter currency : CrystalBank::Types::Currencies::Supported

        @[JSON::Field(description: "List of ledger entries (minimum 2). Debits and credits must balance.")]
        getter entries : Array(EntryRequest)

        @[JSON::Field(description: "Optional metadata for the movement")]
        getter metadata : MetadataRequest?

        @[JSON::Field(format: "date", example: "2026-03-11", description: "Accounting posting date (YYYY-MM-DD)")]
        getter posting_date : String

        @[JSON::Field(description: "Remittance information")]
        getter remittance_information : String

        @[JSON::Field(format: "date", example: "2026-03-12", description: "Value date for the movement (YYYY-MM-DD)")]
        getter value_date : String
      end
    end
  end
end
