require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Approvals
  module Api
    class Approvals < CrystalBank::Api::Base
      include CrystalBank::Domains::Approvals::Api::Requests
      include CrystalBank::Domains::Approvals::Api::Responses
      base "/approvals"

      # List
      # List all approval workflows (optionally filtered by status)
      #
      # Required permission:
      # - **read_approvals_list**
      @[AC::Route::GET("/")]
      def list(
        @[AC::Param::Info(description: "Filter by status: pending, approved, rejected")]
        status : String?,
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20,
      ) : ListResponse(ApprovalResponse)
        authorized?("read_approvals_list", request_scope: false)

        approvals = Approvals::Queries::Approvals.new.list(
          cursor: cursor,
          limit: limit + 1,
          status: status
        ).map do |a|
          ApprovalResponse.new(
            a.id,
            a.domain_event_handle,
            a.reference_aggregate_id,
            a.scope_id,
            a.requester_id,
            a.approval_permission,
            a.required_approvers,
            a.approval_count,
            a.status
          )
        end

        ListResponse(ApprovalResponse).new(
          url: request.resource,
          data: approvals,
          limit: limit
        )
      end

      # Get
      # Get a single approval workflow by ID
      #
      # Required permission:
      # - **read_approvals_detail**
      @[AC::Route::GET("/:id")]
      def show(id : UUID) : ApprovalResponse
        authorized?("read_approvals_detail", request_scope: false)

        approval = Approvals::Queries::Approvals.new.find(id)
        raise CrystalBank::Exception::InvalidArgument.new("Approval not found") if approval.nil?

        ApprovalResponse.new(
          approval.id,
          approval.domain_event_handle,
          approval.reference_aggregate_id,
          approval.scope_id,
          approval.requester_id,
          approval.approval_permission,
          approval.required_approvers,
          approval.approval_count,
          approval.status
        )
      end

      # Approve
      # Submit an approval decision for a pending workflow.
      # The caller must hold the required approval permission in the approval's scope.
      # Self-approval and double-voting are rejected by the aggregate.
      #
      # Required permission:
      # - the domain-specific approve_* permission in the approval's scope
      @[AC::Route::POST("/:id/approve", body: :r)]
      def approve(id : UUID, r : DecisionRequest) : ApprovalResponse
        approval = load_and_authorize_approval(id)

        Approvals::Decide::Commands::Request.new.call(
          approval_id: id,
          actor_id: context.user_id,
          decision: Approvals::Aggregate::DecisionType::Approve,
          comment: r.comment
        )

        updated = Approvals::Queries::Approvals.new.find(id).not_nil!
        ApprovalResponse.new(
          updated.id,
          updated.domain_event_handle,
          updated.reference_aggregate_id,
          updated.scope_id,
          updated.requester_id,
          updated.approval_permission,
          updated.required_approvers,
          updated.approval_count,
          updated.status
        )
      end

      # Reject
      # Submit a rejection decision for a pending workflow.
      # A single rejection immediately closes the workflow.
      # The caller must hold the required approval permission in the approval's scope.
      #
      # Required permission:
      # - the domain-specific approve_* permission in the approval's scope
      @[AC::Route::POST("/:id/reject", body: :r)]
      def reject(id : UUID, r : DecisionRequest) : ApprovalResponse
        approval = load_and_authorize_approval(id)

        Approvals::Decide::Commands::Request.new.call(
          approval_id: id,
          actor_id: context.user_id,
          decision: Approvals::Aggregate::DecisionType::Reject,
          comment: r.comment
        )

        updated = Approvals::Queries::Approvals.new.find(id).not_nil!
        ApprovalResponse.new(
          updated.id,
          updated.domain_event_handle,
          updated.reference_aggregate_id,
          updated.scope_id,
          updated.requester_id,
          updated.approval_permission,
          updated.required_approvers,
          updated.approval_count,
          updated.status
        )
      end

      private def load_and_authorize_approval(id : UUID) : Approvals::Queries::Approvals::Approval
        # Load the approval first (no scope header needed) to obtain the
        # domain-specific permission and scope required for authorization.
        approval = Approvals::Queries::Approvals.new.find(id)
        raise CrystalBank::Exception::InvalidArgument.new("Approval not found") if approval.nil?

        # Authorize: the caller must have the domain-specific approval permission
        # scoped to the same scope as the original request.
        authorized?(approval.approval_permission, scope: approval.scope_id)

        approval
      end

      # Override authorized? to support passing a scope UUID directly
      # (bypassing the x-scope request header for the approve/reject flow).
      private def authorized?(permission : String, scope : UUID)
        token = request.headers["authorization"]?
        raise CrystalBank::Exception::InvalidArgument.new("authorization header is missing") if token.nil?

        jwt = parse_jwt(token)
        parsed_permission = CrystalBank::Permissions.parse(permission)
        available_scopes = CrystalBank::Services::AccessControl.new(roles: jwt.data.roles).available_scopes(parsed_permission)

        raise CrystalBank::Exception::Authorization.new("No permission to perform action '#{permission}' on scope '#{scope}'") unless available_scopes.includes?(scope)

        @context = CrystalBank::Api::Context.new(jwt.data.user, jwt.data.roles, parsed_permission, scope, available_scopes)
      end
    end
  end
end
