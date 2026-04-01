require "./concerns/requests"
require "./concerns/responses"
require "./concerns/blocking"

module CrystalBank::Domains::Accounts
  module Api
    class Accounts < CrystalBank::Api::Base
      include CrystalBank::Domains::Accounts::Api::Requests
      include CrystalBank::Domains::Accounts::Api::Responses
      base "/accounts"

      # Request opening
      # Request the opening of a new account
      #
      # Required permission:
      # - **write_accounts_opening_request**
      @[AC::Route::POST("/open", body: :r)]
      def open(
        r : OpeningRequest,
        @[AC::Param::Info(description: "Idempotency key to ensure unique processing", header: "idempotency_key")]
        idempotency_key : UUID,
      ) : OpeningResponse
        authorized?("write_accounts_opening_request")

        aggregate_id = ::Accounts::Opening::Commands::Request.new.call(r, context)

        OpeningResponse.new(aggregate_id)
      end

      # Request block
      # Request that a block cause be applied to an account. Blocks are stackable —
      # multiple causes can coexist simultaneously and the effective block state is
      # derived by evaluating all active causes:
      # - Any FullBlock cause → FULL_BLOCK
      # - Both Debit and Credit causes present → FULL_BLOCK (implied)
      # - Only Debit causes → DEBIT_BLOCK
      # - Only Credit causes → CREDIT_BLOCK
      #
      # Block type to effect mapping:
      # - **compliance_block** → full_block
      # - **generic_full_block** → full_block
      # - **operations_block** → debit_block
      # - **generic_debit_block** → debit_block
      # - **generic_credit_block** → credit_block
      #
      # The request does not take effect immediately. An approval workflow is created
      # that must be signed off by a user with **write_accounts_blocking_approval**.
      #
      # Required permission:
      # - **write_accounts_blocking_request**
      @[AC::Route::POST("/:account_id/blocks", body: :r)]
      def request_block(
        @[AC::Param::Info(description: "Account ID to apply block to", format: "uuid")]
        account_id : UUID,
        r : BlockingRequest,
      ) : BlockRequestResponse
        authorized?("write_accounts_blocking_request")

        result = ::Accounts::Blocking::Commands::Block.new.call(
          ::Accounts::Api::Requests::BlockingCommandRequest.new(account_id, r.block_type, r.reason),
          context
        )

        Responses::BlockRequestResponse.new(
          block_request_id: result[:block_request_id],
          approval_id: result[:approval_id],
          account_id: account_id,
          block_type: r.block_type.to_s,
          action: "apply",
          reason: r.reason
        )
      end

      # Request unblock
      # Request that an active block cause be removed from an account by its block type.
      # Refers to the cause type (e.g. compliance_block), not a specific block ID.
      # The effective block state is re-evaluated once the removal is approved.
      #
      # The request does not take effect immediately. An approval workflow is created
      # that must be signed off by a user with **write_accounts_unblocking_approval**.
      #
      # Required permission:
      # - **write_accounts_unblocking_request**
      @[AC::Route::DELETE("/:account_id/blocks/:block_type")]
      def request_unblock(
        @[AC::Param::Info(description: "Account ID to remove block from", format: "uuid")]
        account_id : UUID,
        @[AC::Param::Info(description: "Block type to remove (e.g. compliance_block, operations_block)")]
        block_type : CrystalBank::Types::Accounts::BlockType,
        @[AC::Param::Info(description: "Optional reason for removing the block")]
        reason : String? = nil,
      ) : BlockRequestResponse
        authorized?("write_accounts_unblocking_request")

        result = ::Accounts::Blocking::Commands::Unblock.new.call(
          ::Accounts::Api::Requests::UnblockingCommandRequest.new(account_id, block_type, reason),
          context
        )

        Responses::BlockRequestResponse.new(
          block_request_id: result[:block_request_id],
          approval_id: result[:approval_id],
          account_id: account_id,
          block_type: block_type.to_s,
          action: "remove",
          reason: reason
        )
      end

      # Get blocks
      # Get all active block causes on an account and the evaluated effective block state.
      # The effective_block field is not stored — it is computed from the set of active causes.
      #
      # Required permission:
      # - **read_accounts_blocks**
      @[AC::Route::GET("/:account_id/blocks")]
      def get_blocks(
        @[AC::Param::Info(description: "Account ID to retrieve blocks for", format: "uuid")]
        account_id : UUID,
      ) : BlocksResponse
        authorized?("read_accounts_blocks", request_scope: false)

        blocks_response(account_id)
      end

      # List
      # List all accounts
      #
      # Required permission:
      # - **read_accounts_list**
      @[AC::Route::GET("/")]
      def list_accounts(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20,
        @[AC::Param::Info(description: "Filter by scope ID")]
        scope_id : UUID? = nil,
      ) : ListResponse(Responses::Account)
        authorized?("read_accounts_list", request_scope: false)

        accounts = ::Accounts::Queries::Accounts.new.list(context, cursor: cursor, limit: limit + 1, scope_id: scope_id).map do |a|
          Responses::Account.new(
            a.id,
            a.scope_id,
            a.name,
            a.currencies,
            a.customer_ids,
            CrystalBank::Types::Accounts::Type.parse(a.type)
          )
        end

        ListResponse(Responses::Account).new(
          url: request.resource,
          data: accounts,
          limit: limit
        )
      end

      private def blocks_response(account_id : UUID) : BlocksResponse
        active_blocks = ::Accounts::Queries::AccountBlocks.new.list_active(account_id)

        block_types = active_blocks.map(&.block_type_enum)
        effective = CrystalBank::Types::Accounts::EffectiveBlock.evaluate(block_types)

        entries = active_blocks.map do |b|
          Responses::BlockEntry.new(
            block_type: b.block_type,
            applied_at: b.applied_at,
            applied_by: b.applied_by,
            reason: b.reason
          )
        end

        Responses::BlocksResponse.new(
          effective_block: effective.to_s,
          blocks: entries
        )
      end
    end
  end
end
