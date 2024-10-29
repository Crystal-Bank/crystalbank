module CrystalBank::Domains::Accounts
  module Api
    module Requests
      struct OpeningResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the requested account")]
        getter id : String

        def initialize(@id : String)
        end
      end
    end
  end
end
