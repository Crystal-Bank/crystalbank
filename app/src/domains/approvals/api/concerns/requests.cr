module CrystalBank::Domains::Approvals
  module Api
    module Requests
      struct CollectRequest
        include JSON::Serializable

        @[JSON::Field(description: "Optional comment from the approver")]
        getter comment : String = ""
      end
    end
  end
end
