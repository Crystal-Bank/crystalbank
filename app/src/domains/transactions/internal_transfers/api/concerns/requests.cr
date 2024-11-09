module CrystalBank::Domains::Transactions::InternalTransfers
  module Api
    module Requests
      struct InitiationRequest
        include JSON::Serializable

        @[JSON::Field(description: "Amount for the internal transfer")]
        getter amount : Int64

        @[JSON::Field(description: "Account ID of the creditor")]
        getter creditor_account_id : UUID

        @[JSON::Field(description: "Currency of the internal transfer")]
        getter currency : CrystalBank::Types::Currencies::Supported

        @[JSON::Field(description: "Account ID of the debtor")]
        getter debtor_account_id : UUID

        @[JSON::Field(description: "Remittance information for the transfer")]
        getter remittance_information : String
      end
    end
  end
end
