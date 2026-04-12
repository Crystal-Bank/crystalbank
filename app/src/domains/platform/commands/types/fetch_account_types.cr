module CrystalBank::Domains::Platform
  module Types
    module Commands
      class FetchAccountTypes < ES::Command
        def call(c : CrystalBank::Api::Context) : Array(String)
          Queries::AccountTypes.new.list
        end
      end
    end
  end
end
