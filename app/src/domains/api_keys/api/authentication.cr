require "base64"
require "uri"

module CrystalBank::Domains::ApiKeys
  module Api
    class Authentication < CrystalBank::Api::Base
      base "/oauth"

      # RFC 6749 §5.1 successful token response
      struct Response
        include JSON::Serializable

        getter access_token : String
        getter token_type = "Bearer"
        getter expires_in : Int32

        def initialize(@access_token : String, @expires_in : Int32)
        end
      end

      # RFC 6749 §5.2 error response
      struct OAuthError
        include JSON::Serializable

        getter error : String

        def initialize(@error : String)
        end
      end

      # Token endpoint — RFC 6749 §4.4 (client_credentials grant)
      #
      # Accepts application/x-www-form-urlencoded bodies.
      # Also accepts client credentials via HTTP Basic auth (RFC 6749 §2.3.1).
      # When both Authorization header and body params are present, the
      # Authorization header wins per RFC 6749 §2.3.1 convention.
      #
      # Required permission:
      # - none
      @[AC::Route::POST("/token")]
      def authenticate : Nil
        auth_header = request.headers["Authorization"]?
        body_str = request.body.try(&.gets_to_end) || ""
        params = URI::Params.parse(body_str)
        grant_type = params["grant_type"]? || ""

        # Prefer Authorization header; fall back to body params
        client_id, client_secret = if auth_header.try(&.starts_with?("Basic "))
          b64 = auth_header.not_nil![6..]
          decoded = Base64.decode_string(b64)
          sep = decoded.index(':') || decoded.size
          {decoded[0, sep], decoded[(sep + 1)..]}
        else
          {params["client_id"]? || "", params["client_secret"]? || ""}
        end

        unless grant_type == "client_credentials"
          response.status_code = 400
          render json: OAuthError.new("unsupported_grant_type")
          return
        end

        token = ::ApiKeys::Authentication::Commands::Request.new.call(client_id, client_secret)
        render json: Response.new(access_token: token, expires_in: CrystalBank::Env.jwt_ttl)
      rescue CrystalBank::Exception::Authentication | ES::Exception::InvalidState | ES::Exception::NotFound | ArgumentError | Base64::Error
        response.status_code = 401
        render json: OAuthError.new("invalid_client")
      end
    end
  end
end
