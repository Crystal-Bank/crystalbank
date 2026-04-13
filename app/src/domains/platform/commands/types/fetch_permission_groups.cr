module CrystalBank::Domains::Platform
  module Types
    module Commands
      class FetchPermissionGroups < ES::Command
        def call(c : CrystalBank::Api::Context) : Array(Queries::PermissionGroups::GroupEntry)
          Queries::PermissionGroups.new.list
        end
      end
    end
  end
end
