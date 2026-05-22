module CrystalBank::Domains::Accounts
  module VirtualAccount
    module Api
      module Requests
        struct VirtualOpeningRequest
          include JSON::Serializable

          @[JSON::Field(description: "Name of the virtual subaccount")]
          getter name : String
        end
      end

      module Responses
        struct VirtualOpeningResponse
          include JSON::Serializable

          @[JSON::Field(format: "uuid", description: "ID of the requested virtual subaccount")]
          getter id : UUID

          @[JSON::Field(format: "uuid", description: "ID of the parent account")]
          getter parent_id : UUID

          def initialize(@id : UUID, @parent_id : UUID)
          end
        end

        struct VirtualAccount
          include JSON::Serializable

          @[JSON::Field(format: "uuid", description: "ID of the virtual subaccount")]
          getter id : UUID

          @[JSON::Field(format: "uuid", description: "ID of the parent account")]
          getter parent_account_id : UUID

          @[JSON::Field(format: "uuid", description: "Scope of the virtual subaccount")]
          getter scope_id : UUID

          @[JSON::Field(description: "Name of the virtual subaccount")]
          getter name : String

          @[JSON::Field(description: "Supported currencies (inherited from parent)")]
          getter currencies : Array(CrystalBank::Types::Currencies::Supported)

          @[JSON::Field(description: "Account owners (inherited from parent)")]
          getter customer_ids : Array(UUID)

          @[JSON::Field(description: "Status: pending_activation, active, pending_deactivation, inactive")]
          getter status : String

          def initialize(
            @id : UUID,
            @parent_account_id : UUID,
            @scope_id : UUID,
            @name : String,
            @currencies : Array(CrystalBank::Types::Currencies::Supported),
            @customer_ids : Array(UUID),
            @status : String,
          ); end
        end
      end

      class VirtualAccounts < CrystalBank::Api::Base
        include CrystalBank::Domains::Accounts::VirtualAccount::Api::Requests
        include CrystalBank::Domains::Accounts::VirtualAccount::Api::Responses
        base "/accounts"

        # Request virtual subaccount opening
        # Opens a new virtual subaccount under the specified parent account.
        # Currencies, customer IDs, and scope are inherited from the parent and cannot differ.
        #
        # Required permission:
        # - **write_accounts_virtual_opening_request**
        @[AC::Route::POST("/:account_id/virtual", body: :r)]
        def request_virtual_opening(
          @[AC::Param::Info(description: "Parent account ID", format: "uuid")]
          account_id : UUID,
          r : VirtualOpeningRequest,
          @[AC::Param::Info(description: "Idempotency key", header: "idempotency_key")]
          idempotency_key : UUID,
        ) : VirtualOpeningResponse
          authorized?("write_accounts_virtual_opening_request")

          aggregate_id = ::Accounts::VirtualAccount::Opening::Commands::Request.new.call(r, account_id, context)

          VirtualOpeningResponse.new(aggregate_id, account_id)
        end

        # List virtual subaccounts
        # Returns all virtual subaccounts under the specified parent account.
        #
        # Required permission:
        # - **read_accounts_virtual_list**
        @[AC::Route::GET("/:account_id/virtual")]
        def list_virtual_accounts(
          @[AC::Param::Info(description: "Parent account ID", format: "uuid")]
          account_id : UUID,
          @[AC::Param::Info(description: "Pagination cursor")]
          cursor : UUID? = nil,
          @[AC::Param::Info(description: "Page size (default 20)", example: "20")]
          limit : Int32 = 20,
        ) : ListResponse(Responses::VirtualAccount)
          authorized?("read_accounts_virtual_list", request_scope: false)

          accounts = ::Accounts::VirtualAccount::Queries::VirtualAccounts.new.list(account_id, context, cursor: cursor, limit: limit + 1).map do |a|
            Responses::VirtualAccount.new(
              a.id,
              a.parent_account_id,
              a.scope_id,
              a.name,
              a.currencies,
              a.customer_ids,
              a.status
            )
          end

          ListResponse(Responses::VirtualAccount).new(
            url: request.resource,
            data: accounts,
            limit: limit
          )
        end
      end
    end
  end
end
