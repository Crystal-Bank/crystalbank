module CrystalBank::Domains::Transactions::Postings
  module Api
    module Responses
      # Respond with a single account entity
      struct Posting
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the posting")]
        getter id : UUID

        @[JSON::Field(format: "uuid", description: "ID of the account the posting belongs to")]
        getter account_id : UUID

        @[JSON::Field(description: "Amount")]
        getter amount : Int64

        @[JSON::Field(format: "uuid", description: "ID of the creditor account")]
        getter creditor_account_id : UUID

        @[JSON::Field(description: "currency of the posting")]
        getter currency : CrystalBank::Types::Currencies::Available

        @[JSON::Field(format: "uuid", description: "ID of the debtor account")]
        getter debtor_account_id : UUID

        @[JSON::Field(description: "Remittance information")]
        getter remittance_information : String

        def initialize(
          @id : UUID,
          @account_id : UUID,
          @amount : Int64,
          @creditor_account_id : UUID,
          @currency : CrystalBank::Types::Currencies::Available,
          @debtor_account_id : UUID,
          @remittance_information : String,
        ); end
      end
    end
  end
end
