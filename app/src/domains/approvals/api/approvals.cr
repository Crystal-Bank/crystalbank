require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Approvals
  module Api
    class Approvals < CrystalBank::Api::Base
      include CrystalBank::Domains::Approvals::Api::Requests
      include CrystalBank::Domains::Approvals::Api::Responses
      base "/approvals"

      # Collect approval
      # Collect the current user's approval for the given approval process
      #
      # Required permission:
      # - **write_approvals_collection_request**
      @[AC::Route::POST("/:id/collect", body: :r)]
      def collect(
        r : CollectRequest,
        id : UUID,
        @[AC::Param::Info(description: "Idempotency key to ensure unique processing", header: "idempotency_key")]
        idempotency_key : UUID,
      ) : CollectResponse
        authorized?("write_approvals_collection_request")

        ::Approvals::Collection::Commands::Request.new.call(id, r, context)

        # Hydrate the aggregate to check current status
        aggregate = ::Approvals::Aggregate.new(id)
        aggregate.hydrate

        status = aggregate.state.completed ? "completed" : "pending"

        CollectResponse.new(id, status)
      end

      # Reject approval
      # Reject the given approval process.
      # The requestor can reject their own request; users with collection permissions can also reject.
      #
      @[AC::Route::POST("/:id/reject", body: :r)]
      def reject(
        r : RejectRequest,
        id : UUID,
      ) : RejectResponse
        authorized?("write_approvals_rejection_request")

        ::Approvals::Rejection::Commands::Request.new.call(id, r, context)
        RejectResponse.new(id, "rejected")
      end

      # List
      # List all approval processes
      #
      # Required permission:
      # - **read_approvals_list**
      @[AC::Route::GET("/")]
      def list_approvals(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20,
        @[AC::Param::Info(description: "Filter by approval status")]
        status : CrystalBank::Types::Approvals::Status? = nil,
      ) : ListResponse(Responses::Approval)
        authorized?("read_approvals_list", request_scope: false)

        approvals = ::Approvals::Queries::Approvals.new.list(context, cursor: cursor, limit: limit + 1, status: status).map do |a|
          collected = a.collected_approvals.map do |ca|
            Responses::CollectedApproval.new(ca.user_id, ca.permissions, ca.comment)
          end

          Responses::Approval.new(
            a.id,
            a.scope_id,
            a.source_aggregate_type,
            a.source_aggregate_id,
            a.requestor_id,
            a.required_approvals,
            collected,
            a.completed,
            a.rejected
          )
        end

        ListResponse(Responses::Approval).new(
          url: request.resource,
          data: approvals,
          limit: limit
        )
      end
    end
  end
end
