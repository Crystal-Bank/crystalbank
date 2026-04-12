module CrystalBank::Domains::Platform
  module Types
    module Commands
      class FetchCustomerTypes < ES::Command
        def call(c : CrystalBank::Api::Context) : Array(String)
          Queries::CustomerTypes.new.list
        end
      end
    end
  end
end
