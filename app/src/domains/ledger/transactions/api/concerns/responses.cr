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

      struct Posting
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the transaction this posting belongs to")]
        getter id : UUID

        @[JSON::Field(format: "uuid", description: "Account ID of the posting")]
        getter account_id : UUID

        @[JSON::Field(description: "Direction of the posting (DEBIT or CREDIT)")]
        getter direction : String

        @[JSON::Field(description: "Amount of the posting in minor currency units")]
        getter amount : Int64

        @[JSON::Field(description: "Entry type of the posting")]
        getter entry_type : String

        @[JSON::Field(description: "Currency of the posting")]
        getter currency : String

        @[JSON::Field(format: "date", description: "Posting date")]
        getter posting_date : String?

        @[JSON::Field(format: "date", description: "Value date")]
        getter value_date : String?

        @[JSON::Field(description: "Remittance information")]
        getter remittance_information : String

        @[JSON::Field(description: "Payment type")]
        getter payment_type : String?

        @[JSON::Field(description: "External reference")]
        getter external_ref : String?

        @[JSON::Field(description: "Channel")]
        getter channel : String?

        @[JSON::Field(description: "Internal note")]
        getter internal_note : String?

        def initialize(
          @id : UUID,
          @account_id : UUID,
          @direction : String,
          @amount : Int64,
          @entry_type : String,
          @currency : String,
          @posting_date : String?,
          @value_date : String?,
          @remittance_information : String,
          @payment_type : String?,
          @external_ref : String?,
          @channel : String?,
          @internal_note : String?,
        ); end
      end
    end
  end
end
