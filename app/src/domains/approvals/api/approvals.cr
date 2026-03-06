require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Approvals
  module Api
    class Approvals < CrystalBank::Api::Base
      include CrystalBank::Domains::Approvals::Api::Requests
      include CrystalBank::Domains::Approvals::Api::Responses
      base "/approvals"

      # List approvals
      #
      # Required permission: **read_approvals_list**
      @[AC::Route::GET("/")]
      def list(
        @[AC::Param::Info(description: "Optional cursor for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Filter by status: pending, approved, rejected")]
        status : String?,
        @[AC::Param::Info(description: "Limit (default 20)")]
        limit : Int32 = 20,
      ) : ListResponse(Responses::ApprovalResponse)
        authorized?("read_approvals_list", request_scope: false)

        approvals = ::Approvals::Queries::Approvals.new.list(
          cursor: cursor,
          limit: limit + 1,
          status: status,
          scope_ids: context.available_scopes
        ).map { |a| Responses::ApprovalResponse.new(a) }

        ListResponse(Responses::ApprovalResponse).new(
          url: request.resource,
          data: approvals,
          limit: limit
        )
      end

      # Get a single approval
      #
      # Required permission: **read_approvals_list**
      @[AC::Route::GET("/:id")]
      def show(id : UUID) : ApprovalResponse
        authorized?("read_approvals_list", request_scope: false)

        record = ::Approvals::Queries::Approvals.new.find(id)
        raise ES::Exception::NotFound.new("Approval #{id} not found") unless record

        ApprovalResponse.new(record)
      end

      # Submit an approval decision (approve or reject)
      #
      # Required permission: **write_approvals_submission_request**
      # Additionally the actor must hold one of the permissions required by the
      # current approval step (validated in ProcessRequest).
      @[AC::Route::POST("/:id/submit", body: :r)]
      def submit(
        id : UUID,
        r : SubmissionRequest,
        @[AC::Param::Info(header: "idempotency_key")]
        idempotency_key : UUID,
      ) : AcceptedResponse
        authorized?("write_approvals_submission_request", request_scope: false)

        ::Approvals::Submission::Commands::Request.new.call(
          approval_id: id,
          decision: r.decision,
          reason: r.reason,
          actor_id: context.user_id
        )

        AcceptedResponse.new(id)
      end
    end
  end
end
