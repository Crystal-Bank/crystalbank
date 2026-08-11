module CrystalBank::Domains::Platform
  module Types
    module Commands
      class FetchPermissions
        def call(c : CrystalBank::Api::Context) : Array(String)
          Queries::Permissions.new.list
        end
      end
    end
  end
end
