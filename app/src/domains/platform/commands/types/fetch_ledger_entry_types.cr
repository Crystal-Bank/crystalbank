module CrystalBank::Domains::Platform
  module Types
    module Commands
      class FetchLedgerEntryTypes < ES::Command
        def call(c : CrystalBank::Api::Context) : Array(String)
          Queries::LedgerEntryTypes.new.list
        end
      end
    end
  end
end
