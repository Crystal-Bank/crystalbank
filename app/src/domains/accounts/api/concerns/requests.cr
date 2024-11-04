module CrystalBank::Domains::Accounts
  module Api
    module Requests
      struct OpeningRequest
        include JSON::Serializable

        @[JSON::Field(description: "List of supported currencies")]
        getter currencies : Array(CrystalBank::Types::Currencies::Supported)

        @[JSON::Field(description: "Type of the account")]
        getter type : CrystalBank::Types::Accounts::Type
      end
    end
  end
end
