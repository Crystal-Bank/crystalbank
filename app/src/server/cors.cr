require "uri"

module CrystalBank
  module Server
    # Handles CORS for cross-origin requests from the dashboard to the API.
    # On OPTIONS preflight requests it short-circuits with 204.
    # On all other cross-origin requests it injects Access-Control-* headers
    # when the Origin matches the configured DASHBOARD_DOMAIN.
    class CorsHandler
      include HTTP::Handler

      ALLOW_METHODS  = "GET, POST, PUT, PATCH, DELETE, OPTIONS"
      ALLOW_HEADERS  = "Authorization, Content-Type, X-Scope, idempotency_key"
      EXPOSE_HEADERS = "X-Request-ID"
      MAX_AGE        = "86400"

      def call(context : HTTP::Server::Context)
        origin = context.request.headers["Origin"]?
        allowed = !!(origin && allowed_origin?(origin))

        if context.request.method == "OPTIONS"
          if allowed
            set_cors_headers(context.response.headers, origin.not_nil!)
          end
          context.response.status_code = 204
          return
        end

        set_cors_headers(context.response.headers, origin.not_nil!) if allowed
        call_next(context)
        set_cors_headers(context.response.headers, origin.not_nil!) if allowed
      end

      private def set_cors_headers(headers : HTTP::Headers, origin : String)
        headers["Access-Control-Allow-Origin"] = origin
        headers["Access-Control-Allow-Methods"] = ALLOW_METHODS
        headers["Access-Control-Allow-Headers"] = ALLOW_HEADERS
        headers["Access-Control-Expose-Headers"] = EXPOSE_HEADERS
        headers["Access-Control-Max-Age"] = MAX_AGE
        headers["Vary"] = "Origin"
      end

      private def allowed_origin?(origin : String) : Bool
        host = URI.parse(origin).host || ""
        host == CrystalBank::Env.dashboard_domain || host == "localhost" || host == "127.0.0.1"
      rescue
        false
      end
    end
  end
end
