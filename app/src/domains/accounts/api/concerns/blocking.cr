module CrystalBank::Domains::Accounts
  module Api
    module Requests
      # HTTP body for the apply-block endpoint
      struct BlockingRequest
        include JSON::Serializable

        @[JSON::Field(description: "Type of block to apply")]
        getter block_type : CrystalBank::Types::Accounts::BlockType

        @[JSON::Field(description: "Optional reason for applying the block")]
        getter reason : String?
      end

      # Unified command request built by the API layer from URL params + body
      struct BlockingCommandRequest
        getter account_id : UUID
        getter block_type : CrystalBank::Types::Accounts::BlockType
        getter action : String
        getter reason : String?

        def initialize(@account_id, @block_type, @action, @reason); end
      end
    end

    module Responses
      # Returned immediately after a block or unblock is requested.
      # The block does not take effect until the approval workflow completes.
      struct BlockRequestResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the block request aggregate")]
        getter block_request_id : UUID

        @[JSON::Field(format: "uuid", description: "ID of the approval workflow that must be completed")]
        getter approval_id : UUID

        @[JSON::Field(format: "uuid", description: "Account the block request targets")]
        getter account_id : UUID

        @[JSON::Field(description: "Block type that will be applied or removed once approved")]
        getter block_type : String

        @[JSON::Field(description: "Whether the block is being applied or removed")]
        getter action : String

        @[JSON::Field(description: "Reason provided by the requestor")]
        getter reason : String?

        @[JSON::Field(description: "Current status of the request")]
        getter status : String

        def initialize(
          @block_request_id : UUID,
          @approval_id : UUID,
          @account_id : UUID,
          @block_type : String,
          @action : String,
          @reason : String?,
          @status : String = "pending_approval",
        ); end
      end

      struct BlockEntry
        include JSON::Serializable

        @[JSON::Field(description: "Block type cause")]
        getter block_type : String

        @[JSON::Field(description: "Timestamp when the block was applied")]
        getter applied_at : Time

        @[JSON::Field(format: "uuid", description: "ID of the user who applied the block")]
        getter applied_by : UUID

        @[JSON::Field(description: "Reason for the block")]
        getter reason : String?

        def initialize(
          @block_type : String,
          @applied_at : Time,
          @applied_by : UUID,
          @reason : String?,
        ); end
      end

      struct BlocksResponse
        include JSON::Serializable

        @[JSON::Field(description: "Evaluated effective block state derived from all active block causes")]
        getter effective_block : String

        @[JSON::Field(description: "List of active block causes on the account")]
        getter blocks : Array(BlockEntry)

        def initialize(
          @effective_block : String,
          @blocks : Array(BlockEntry),
        ); end
      end
    end
  end
end
