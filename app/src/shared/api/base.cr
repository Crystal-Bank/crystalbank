require "action-controller"
require "./responses"

module CrystalBank
  module Api
    abstract class Base < ActionController::Base
      # include CrystalBank::Api::Authorization
      include CrystalBank::Api::Responses

      @[AC::Route::Filter(:before_action)]
      def set_request_id
        request_id = UUID.v7.to_s
        Log.context.set(
          client_ip: client_ip,
          request_id: request_id
        )
        response.headers["X-Request-ID"] = request_id
      end

      # Error handling
      # TODO: Annotation do not properly work when included from a module
      @[AC::Route::Exception(CrystalBank::Exception::InvalidArgument, status_code: HTTP::Status::BAD_REQUEST)]
      @[AC::Route::Exception(ES::Exception::NotFound, status_code: HTTP::Status::NOT_FOUND)]
      def error_reponse(error : ES::Exception::Error) : ErrorResponse
        Log.error { error.info.to_json }
        Log.error { error.backtrace } if error.print_backtrace?

        id = error.info.id
        type = error.info.type
        message = error.info.message
        timestamp = error.info.timestamp

        ErrorResponse.new(id, message.to_s, timestamp, type)
      end

      @[AC::Route::Exception(JSON::SerializableError, status_code: HTTP::Status::BAD_REQUEST)]
      @[AC::Route::Exception(JSON::ParseException, status_code: HTTP::Status::BAD_REQUEST)]
      @[AC::Route::Exception(DB::MappingException, status_code: HTTP::Status::INTERNAL_SERVER_ERROR)]
      @[AC::Route::Exception(ArgumentError, status_code: HTTP::Status::BAD_REQUEST)]
      def error_response(error : ::Exception)
        Log.error { error }
        Log.error { error.backtrace }

        id = UUID.v7
        type = error.class.to_s
        message = error.message
        timestamp = Time.utc

        ErrorResponse.new(id, message.to_s, timestamp, type)
      end
    end
  end
end
