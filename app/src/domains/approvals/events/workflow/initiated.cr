module CrystalBank::Domains::Approvals
  module Workflow
    module Events
      class Initiated < ES::Event
        @@type = "Approval"
        @@handle = "approvals.workflow.initiated"

        struct Body < ES::Event::Body
          getter domain_event_handle : String
          getter reference_aggregate_id : UUID
          getter scope_id : UUID
          getter requester_id : UUID
          getter approval_permission : String
          getter required_approvers : Int32

          def initialize(
            @comment : String,
            @domain_event_handle : String,
            @reference_aggregate_id : UUID,
            @scope_id : UUID,
            @requester_id : UUID,
            @approval_permission : String,
            @required_approvers : Int32,
          ); end
        end

        def initialize(@header : ES::Event::Header, body : JSON::Any)
          @body = Body.from_json(body.to_json)
        end

        def initialize(
          actor_id : UUID,
          command_handler : String,
          aggregate_id : UUID,
          domain_event_handle : String,
          reference_aggregate_id : UUID,
          scope_id : UUID,
          requester_id : UUID,
          approval_permission : String,
          required_approvers : Int32,
          comment = "",
        )
          @header = Header.new(
            actor_id: actor_id,
            aggregate_id: aggregate_id,
            aggregate_type: @@type,
            aggregate_version: 1,
            command_handler: command_handler,
            event_handle: @@handle
          )
          @body = Body.new(
            comment: comment,
            domain_event_handle: domain_event_handle,
            reference_aggregate_id: reference_aggregate_id,
            scope_id: scope_id,
            requester_id: requester_id,
            approval_permission: approval_permission,
            required_approvers: required_approvers
          )
        end
      end
    end
  end
end
