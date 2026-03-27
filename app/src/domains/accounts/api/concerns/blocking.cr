module CrystalBank::Domains::Accounts
  module Api
    module Requests
      struct BlockingRequest
        include JSON::Serializable

        @[JSON::Field(description: "Type of block to apply")]
        getter block_type : CrystalBank::Types::Accounts::BlockType

        @[JSON::Field(description: "Optional reason for applying the block")]
        getter reason : String?
      end

      struct UnblockingRequest
        include JSON::Serializable

        @[JSON::Field(description: "Optional reason for removing the block")]
        getter reason : String?
      end
    end

    module Responses
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
