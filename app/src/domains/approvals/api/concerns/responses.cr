module CrystalBank::Domains::Approvals
  module Api
    module Responses
      struct CollectedApproval
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the user who approved")]
        getter user_id : UUID

        @[JSON::Field(description: "Permissions the user is eligible to satisfy")]
        getter permissions : Array(String)

        def initialize(@user_id : UUID, @permissions : Array(String)); end
      end

      struct CollectResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the approval process")]
        getter id : UUID

        @[JSON::Field(description: "Current status of the approval process")]
        getter status : String

        def initialize(@id : UUID, @status : String); end
      end

      struct Approval
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the approval process")]
        getter id : UUID

        @[JSON::Field(format: "uuid", description: "Scope of the data point")]
        getter scope_id : UUID

        @[JSON::Field(description: "Type of the source aggregate")]
        getter source_aggregate_type : String

        @[JSON::Field(format: "uuid", description: "ID of the source aggregate")]
        getter source_aggregate_id : UUID

        @[JSON::Field(format: "uuid", description: "ID of the user who initiated the request")]
        getter requestor_id : UUID?

        @[JSON::Field(description: "List of required approval permissions")]
        getter required_approvals : Array(String)

        @[JSON::Field(description: "List of collected approvals")]
        getter collected_approvals : Array(CollectedApproval)

        @[JSON::Field(description: "Whether the approval process is completed")]
        getter completed : Bool

        def initialize(
          @id : UUID,
          @scope_id : UUID,
          @source_aggregate_type : String,
          @source_aggregate_id : UUID,
          @requestor_id : UUID?,
          @required_approvals : Array(String),
          @collected_approvals : Array(CollectedApproval),
          @completed : Bool,
        ); end
      end
    end
  end
end
