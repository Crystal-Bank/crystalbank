require "./concerns/requests"
require "./concerns/responses"

module CrystalBank::Domains::Approvals
  module Api
    class Approvals < CrystalBank::Api::Base
      # include CrystalBank::Domains::Approvals::Api::Requests
      include CrystalBank::Domains::Approvals::Api::Responses
      base "/approvals"

      # List
      # List approvals
      #
      # Required permission:
      # - **read_approvals_list**
      @[AC::Route::GET("/")]
      def list_approvals(
        @[AC::Param::Info(description: "Optional cursor parameter for pagination")]
        cursor : UUID?,
        @[AC::Param::Info(description: "Limit parameter for pagination (default 20)", example: "20")]
        limit : Int32 = 20,
      ) : ListResponse(Responses::Approval)
        authorized?("read_approvals_list", request_scope: false)

        approvals = [UUID.v7].map do |a|
          Responses::Approval.new(
            a
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