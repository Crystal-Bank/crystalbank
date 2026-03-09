module CrystalBank::Domains::Ledger::Transactions
  module Api
    module Responses
      struct TransactionResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the created ledger transaction")]
        getter id : UUID

        def initialize(@id : UUID)
        end
      end
    end
  end
end
