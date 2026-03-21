module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Api
    module Responses
      struct CreditTransferResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the created SEPA Credit Transfer")]
        getter id : UUID

        def initialize(@id : UUID)
        end
      end

      struct CreditTransfer
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the SEPA Credit Transfer")]
        getter id : UUID

        @[JSON::Field(format: "uuid", description: "Data scope")]
        getter scope_id : UUID

        @[JSON::Field(description: "End-to-end reference")]
        getter end_to_end_id : String

        @[JSON::Field(format: "uuid", description: "Debtor (payer) account ID")]
        getter debtor_account_id : UUID

        @[JSON::Field(format: "uuid", description: "Settlement nostro account ID")]
        getter settlement_account_id : UUID

        @[JSON::Field(description: "Beneficiary IBAN")]
        getter creditor_iban : String

        @[JSON::Field(description: "Beneficiary name")]
        getter creditor_name : String

        @[JSON::Field(description: "Beneficiary BIC")]
        getter creditor_bic : String?

        @[JSON::Field(description: "Amount in EUR cents")]
        getter amount : Int64

        @[JSON::Field(description: "Currency (always EUR)")]
        getter currency : String

        @[JSON::Field(format: "date", description: "Execution date")]
        getter execution_date : String

        @[JSON::Field(description: "Remittance information")]
        getter remittance_information : String

        @[JSON::Field(description: "Status: pending | executed")]
        getter status : String

        @[JSON::Field(format: "uuid", description: "Ledger transaction ID (set once executed)")]
        getter ledger_transaction_id : UUID?

        @[JSON::Field(description: "Created at")]
        getter created_at : String

        def initialize(
          @id : UUID,
          @scope_id : UUID,
          @end_to_end_id : String,
          @debtor_account_id : UUID,
          @settlement_account_id : UUID,
          @creditor_iban : String,
          @creditor_name : String,
          @creditor_bic : String?,
          @amount : Int64,
          @currency : String,
          @execution_date : String,
          @remittance_information : String,
          @status : String,
          @ledger_transaction_id : UUID?,
          @created_at : String,
        ); end
      end
    end
  end
end
