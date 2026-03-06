module CrystalBank::Domains::Approvals
  module Decision
    module Events
      class Made < ES::Event
        @@type = "Approval"
        @@handle = "approvals.decision.made"

        struct Body < ES::Event::Body
          getter approver_id : UUID
          getter decision : CrystalBank::Domains::Approvals::Aggregate::DecisionType

          def initialize(
            @comment : String,
            @approver_id : UUID,
            @decision : CrystalBank::Domains::Approvals::Aggregate::DecisionType,
          ); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end

        def initialize(
          actor_id : UUID,
          command_handler : String,
          aggregate_id : UUID,
          aggregate_version : Int32,
          approver_id : UUID,
          decision : CrystalBank::Domains::Approvals::Aggregate::DecisionType,
          comment = "",
        )
          @header = Header.new(
            actor_id: actor_id,
            aggregate_id: aggregate_id,
            aggregate_type: @@type,
            aggregate_version: aggregate_version,
            command_handler: command_handler,
            event_handle: @@handle
          )
          @body = Body.new(
            comment: comment,
            approver_id: approver_id,
            decision: decision
          )
        end
      end
    end
  end
end
