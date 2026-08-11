module CrystalBank::Domains::Platform
  module Types
    module Commands
      class FetchCurrencies
        def call(c : CrystalBank::Api::Context) : Array(String)
          Queries::Currencies.new.list
        end
      end
    end
  end
end
