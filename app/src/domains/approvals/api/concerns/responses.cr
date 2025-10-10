module CrystalBank::Domains::Approvals
  module Api
    module Responses
      struct Approval
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the approval request")]
        getter id : UUID

        def initialize(@id)
        end
      end
    end
  end
end
