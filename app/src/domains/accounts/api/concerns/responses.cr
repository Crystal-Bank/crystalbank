module CrystalBank::Domains::Accounts
  module Api
    module Responses
      # Response to an account closure request
      struct ClosureResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the account being closed")]
        getter account_id : UUID

        @[JSON::Field(format: "uuid", description: "ID of the closure request aggregate")]
        getter closure_request_id : UUID

        @[JSON::Field(format: "uuid", description: "ID of the approval workflow that must be completed")]
        getter approval_id : UUID

        @[JSON::Field(description: "Current status of the closure request")]
        getter status : String

        def initialize(
          @account_id : UUID,
          @closure_request_id : UUID,
          @approval_id : UUID,
          @status : String = "closure_pending",
        ); end
      end

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

        @[JSON::Field(description: "Name of the account")]
        getter name : String

        @[JSON::Field(description: "Supported currencies of the account")]
        getter currencies : Array(CrystalBank::Types::Currencies::Supported)

        @[JSON::Field(description: "List of account owners (customers)")]
        getter customer_ids : Array(UUID)

        @[JSON::Field(description: "Type of the account")]
        getter type : CrystalBank::Types::Accounts::Type

        @[JSON::Field(description: "Status of the account: active, pending_approval")]
        getter status : String

        def initialize(
          @id : UUID,
          @scope_id : UUID,
          @name : String,
          @currencies : Array(CrystalBank::Types::Currencies::Supported),
          @customer_ids : Array(UUID),
          @type : CrystalBank::Types::Accounts::Type,
          @status : String,
        ); end
      end
    end
  end
end
