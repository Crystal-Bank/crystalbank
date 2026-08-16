module CrystalBank::Domains::Ledger::Transactions
  module Api
    module Responses
      struct TransactionResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the created ledger transaction")]
        getter id : UUID

        def initialize(@id : UUID)
        end
      end

      struct Amount
        include JSON::Serializable

        @[JSON::Field(description: "Amount in minor currency units (e.g. cents)")]
        getter value : Int64

        @[JSON::Field(description: "ISO 4217 currency code")]
        getter currency : String

        @[JSON::Field(description: "Number of minor-unit decimal places for this currency")]
        getter precision : Int32

        def initialize(@value : Int64, @currency : String, @precision : Int32); end
      end

      # Per-entry-type `details` payload on a posting. Which struct is used is
      # determined by the posting's `entry_type` (e.g. "sepa_credit_transfer" ->
      # SepaCreditTransferDetails). As more entry types gain their own details,
      # add their structs here and widen `Posting#details` to the union.
      struct SepaCreditTransferDetails
        include JSON::Serializable

        @[JSON::Field(description: "External reference (e.g. ISO-20022 end-to-end ID)")]
        getter external_ref : String?

        def initialize(@external_ref : String?); end
      end

      struct Posting
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "Unique ID of the posting")]
        getter id : UUID

        @[JSON::Field(format: "uuid", description: "ID of the transaction this posting belongs to")]
        getter transaction_id : UUID

        @[JSON::Field(format: "uuid", description: "Account ID of the posting")]
        getter account_id : UUID

        @[JSON::Field(description: "Direction of the posting (debit or credit)")]
        getter direction : String

        @[JSON::Field(description: "Amount of the posting")]
        getter amount : Amount

        @[JSON::Field(description: "Entry type of the posting; determines the shape of `details`")]
        getter entry_type : String

        @[JSON::Field(format: "date", description: "Posting date")]
        getter posting_date : String

        @[JSON::Field(format: "date", description: "Value date")]
        getter value_date : String

        @[JSON::Field(description: "Remittance information")]
        getter remittance_information : String

        @[JSON::Field(description: "Entry-type-specific metadata, shape depends on entry_type")]
        getter details : SepaCreditTransferDetails?

        def initialize(
          @id : UUID,
          @transaction_id : UUID,
          @account_id : UUID,
          @direction : String,
          @amount : Amount,
          @entry_type : String,
          @posting_date : String?,
          @value_date : String?,
          @remittance_information : String,
          @details : SepaCreditTransferDetails?,
        ); end
      end
    end
  end
end
