require "action-controller"

module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Api
    module Requests
      struct CreditTransferRequest
        include JSON::Serializable

        @[JSON::Field(description: "Unique end-to-end reference for this payment (max 35 chars). Auto-generated if omitted.")]
        getter end_to_end_id : String?

        @[JSON::Field(description: "Internal account ID to debit (the payer's account)")]
        getter debtor_account_id : UUID

        @[JSON::Field(description: "IBAN of the beneficiary")]
        getter creditor_iban : String

        @[JSON::Field(description: "Name of the beneficiary")]
        getter creditor_name : String

        @[JSON::Field(description: "BIC of the beneficiary's bank (optional for intra-SEPA)")]
        getter creditor_bic : String?

        @[JSON::Field(description: "Amount in EUR cents (minor units). Must be > 0.")]
        getter amount : Int64

        @[JSON::Field(description: "Currency. Must be 'EUR' for SEPA Credit Transfers.")]
        getter currency : String

        @[JSON::Field(format: "date", description: "Requested execution date (YYYY-MM-DD). Defaults to today if omitted.")]
        getter execution_date : String?

        @[JSON::Field(description: "Remittance information / payment reference (max 140 chars)")]
        getter remittance_information : String
      end
    end
  end
end
