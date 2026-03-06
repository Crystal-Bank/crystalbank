module CrystalBank::Domains::Approvals
  module Api
    module Requests
      struct SubmissionRequest
        include JSON::Serializable

        @[JSON::Field(description: "Decision: 'approved' or 'rejected'")]
        getter decision : String

        @[JSON::Field(description: "Optional reason / comment")]
        getter reason : String?
      end
    end
  end
end
