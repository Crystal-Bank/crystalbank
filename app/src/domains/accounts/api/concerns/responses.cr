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

        @[JSON::Field(description: "Supported currencies of the account")]
        getter currencies : Array(CrystalBank::Types::Currencies::Available)

        @[JSON::Field(description: "Type of the account")]
        getter type : CrystalBank::Types::Accounts::Type

        def initialize(
          @id : UUID,
          @currencies : Array(CrystalBank::Types::Currencies::Available),
          @type : CrystalBank::Types::Accounts::Type
        ); end
      end
    end
  end
end
