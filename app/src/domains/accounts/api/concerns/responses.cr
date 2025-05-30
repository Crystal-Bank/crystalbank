module CrystalBank::Domains::Accounts
  module Api
    module Responses
      # Response to an account opening request
      struct OpeningResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the requested account")]
        getter id : UUID

        def initialize(@id : UUID)
        end
      end

      # Respond with a single account entity
      struct Account
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the requested account")]
        getter id : UUID

        @[JSON::Field(format: "uuid", description: "Scope of the data point")]
        getter scope_id : UUID

        @[JSON::Field(description: "Supported currencies of the account")]
        getter currencies : Array(CrystalBank::Types::Currencies::Supported)

        @[JSON::Field(description: "List of account owners (customers)")]
        getter customer_ids : Array(UUID)

        @[JSON::Field(description: "Type of the account")]
        getter type : CrystalBank::Types::Accounts::Type

        def initialize(
          @id : UUID,
          @scope_id : UUID,
          @currencies : Array(CrystalBank::Types::Currencies::Supported),
          @customer_ids : Array(UUID),
          @type : CrystalBank::Types::Accounts::Type,
        ); end
      end
    end
  end
end
