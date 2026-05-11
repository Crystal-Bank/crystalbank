module CrystalBank::Domains::Accounts
  module Api
    module Requests
      struct ClosureRequest
        include JSON::Serializable

        @[JSON::Field(description: "Reason for closing the account")]
        getter reason : CrystalBank::Types::Accounts::ClosureReason

        @[JSON::Field(description: "Optional free-text comment elaborating on the closure reason")]
        getter closure_comment : String?
      end

      struct OpeningRequest
        include JSON::Serializable

        @[JSON::Field(description: "Name of the account")]
        getter name : String

        @[JSON::Field(description: "List of supported currencies")]
        getter currencies : Array(CrystalBank::Types::Currencies::Supported)

        @[JSON::Field(description: "List of account owners (customers)")]
        getter customer_ids : Array(UUID)

        @[JSON::Field(description: "Type of the account")]
        getter type : CrystalBank::Types::Accounts::Type
      end
    end
  end
end
