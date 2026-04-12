require "./concerns/type_responses"

module CrystalBank::Domains::Platform
  module Api
    class Types < CrystalBank::Api::Base
      include CrystalBank::Domains::Platform::Api::TypeResponses
      base "/platform/types"

      # Get permissions
      # Returns a sorted list of all permission values available in the platform.
      # Intended to populate form dropdowns and value pickers on the frontend.
      #
      # Required permission:
      # - **read_platform_types**
      @[AC::Route::GET("/permissions")]
      def get_permissions : TypesResponse
        authorized?("read_platform_types", request_scope: false)

        values = ::Platform::Types::Commands::FetchPermissions.new.call(context)
        TypesResponse.new(values)
      end

      # Get account types
      # Returns a sorted list of all account type values available in the platform.
      # Intended to populate form dropdowns and value pickers on the frontend.
      #
      # Required permission:
      # - **read_platform_types**
      @[AC::Route::GET("/account-types")]
      def get_account_types : TypesResponse
        authorized?("read_platform_types", request_scope: false)

        values = ::Platform::Types::Commands::FetchAccountTypes.new.call(context)
        TypesResponse.new(values)
      end

      # Get currencies
      # Returns a sorted list of all ISO 4217 currency codes available in the platform.
      # Intended to populate form dropdowns and value pickers on the frontend.
      #
      # Required permission:
      # - **read_platform_types**
      @[AC::Route::GET("/currencies")]
      def get_currencies : TypesResponse
        authorized?("read_platform_types", request_scope: false)

        values = ::Platform::Types::Commands::FetchCurrencies.new.call(context)
        TypesResponse.new(values)
      end

      # Get customer types
      # Returns a sorted list of all customer type values available in the platform.
      # Intended to populate form dropdowns and value pickers on the frontend.
      #
      # Required permission:
      # - **read_platform_types**
      @[AC::Route::GET("/customer-types")]
      def get_customer_types : TypesResponse
        authorized?("read_platform_types", request_scope: false)

        values = ::Platform::Types::Commands::FetchCustomerTypes.new.call(context)
        TypesResponse.new(values)
      end

      # Get ledger transaction entry types
      # Returns a sorted list of all ledger transaction entry type values available in the platform.
      # Intended to populate form dropdowns and value pickers on the frontend.
      #
      # Required permission:
      # - **read_platform_types**
      @[AC::Route::GET("/ledger-entry-types")]
      def get_ledger_entry_types : TypesResponse
        authorized?("read_platform_types", request_scope: false)

        values = ::Platform::Types::Commands::FetchLedgerEntryTypes.new.call(context)
        TypesResponse.new(values)
      end
    end
  end
end
