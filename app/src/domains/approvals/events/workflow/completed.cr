module CrystalBank::Domains::Approvals
  module Workflow
    module Events
      class Completed < ES::Event
        @@type = "Approval"
        @@handle = "approvals.workflow.completed"

        struct Body < ES::Event::Body
          getter status : CrystalBank::Domains::Approvals::Aggregate::Status

          def initialize(
            @comment : String,
            @status : CrystalBank::Domains::Approvals::Aggregate::Status,
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
          status : CrystalBank::Domains::Approvals::Aggregate::Status,
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
            status: status
          )
        end
      end
    end
  end
end
