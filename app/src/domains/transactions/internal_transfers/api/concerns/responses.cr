module CrystalBank::Domains::Transactions::InternalTransfers
  module Api
    module Responses
      # Response to an internal transfer initiation request
      struct InitiationResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the requested account")]
        getter id : UUID

        def initialize(@id : UUID)
        end
      end

      # TODO
      # # Respond with a single account entity
      # struct Account
      #   include JSON::Serializable

      #   @[JSON::Field(format: "uuid", description: "ID of the requested account")]
      #   getter id : UUID

      #   @[JSON::Field(description: "Supported currencies of the account")]
      #   getter currencies : Array(CrystalBank::Types::Currencies::Supported)

      #   @[JSON::Field(description: "Type of the account")]
      #   getter type : CrystalBank::Types::Accounts::Type

      #   def initialize(
      #     @id : UUID,
      #     @currencies : Array(CrystalBank::Types::Currencies::Supported),
      #     @type : CrystalBank::Types::Accounts::Type
      #   ); end
      # end
    end
  end
end
