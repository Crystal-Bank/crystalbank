module CrystalBank
  # @TODO: Many types should be dynamically configurable in the interface
  module Types
    extend self

    @@types_folder = "./src/config/types"

    def account_types_yaml
      File.read([@@types_folder, "account_types.yml"].join("/"))
    end

    def currencies_yaml
      File.read([@@types_folder, "currencies.yml"].join("/"))
    end
  end
end
