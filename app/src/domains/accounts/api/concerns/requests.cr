module CrystalBank::Domains::Accounts
  module Api
    module Requests
      struct OpeningRequest
        include JSON::Serializable
        @[JSON::Field(description: "List of supported currencies")]
        getter currencies : Array(String)

        @[JSON::Field(description: "List of customers owning the account")]
        getter customer_ids : Array(String)

        @[JSON::Field(description: "Type of the account")]
        getter type : String
      end
    end
  end
end
