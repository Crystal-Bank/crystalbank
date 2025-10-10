require "action-controller/server"

class ApiErrorHandler
  include HTTP::Handler
  include CrystalBank::Api::Responses

  def call(context)
    begin
      call_next(context)
    rescue ex : ::Exception
      context.response.status_code = 500
      context.response.content_type = "application/json"
      context.response.print(
        ErrorResponse.new(UUID.v7, ex.message.to_s, Time.utc, ex.class.to_s).to_json
      )
    end
  end
end

ActionController::Server.before ApiErrorHandler.new
