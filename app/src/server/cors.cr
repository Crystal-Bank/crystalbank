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

        if origin && allowed_origin?(origin)
          h = context.response.headers
          h["Access-Control-Allow-Origin"] = origin
          h["Access-Control-Allow-Methods"] = ALLOW_METHODS
          h["Access-Control-Allow-Headers"] = ALLOW_HEADERS
          h["Access-Control-Expose-Headers"] = EXPOSE_HEADERS
          h["Access-Control-Max-Age"] = MAX_AGE
          h["Access-Control-Allow-Credentials"] = "true" # Critical for Auth
          h["Vary"] = "Origin"                           # Critical for dynamic origins
        end

        if context.request.method == "OPTIONS"
          context.response.status_code = 204
          return
        end

        call_next(context)
      end

      private def allowed_origin?(origin : String) : Bool
        host = URI.parse(origin).host || ""
        CrystalBank.print_verbose("CORS request", "from origin: #{origin}, host: #{host}, dashboard domain: #{CrystalBank::Env.dashboard_domain}")
        host == CrystalBank::Env.dashboard_domain || host == "localhost" || host == "127.0.0.1"
      rescue
        false
      end
    end
  end
end
