module CrystalBank::Domains::Platform
  module Queries
    class Permissions
      def list : Array(String)
        CrystalBank::Permissions.values.map(&.to_s).sort
      end
    end

    class AccountTypes
      def list : Array(String)
        CrystalBank::Types::Accounts::Type.values.map(&.to_s).sort
      end
    end

    class Currencies
      def list : Array(String)
        CrystalBank::Types::Currencies::Supported.values.map(&.to_s).sort
      end
    end

    class CustomerTypes
      def list : Array(String)
        CrystalBank::Types::Customers::Type.values.map(&.to_s).sort
      end
    end

    class LedgerEntryTypes
      def list : Array(String)
        CrystalBank::Types::LedgerTransactions::EntryType.values.map(&.to_s).sort
      end
    end
  end
end
