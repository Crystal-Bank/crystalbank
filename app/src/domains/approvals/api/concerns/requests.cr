module CrystalBank::Domains::Approvals
  module Api
    module Requests
      struct DecisionRequest
        include JSON::Serializable

        @[JSON::Field(description: "Optional comment explaining the decision")]
        getter comment : String = ""
      end
    end
  end
end
