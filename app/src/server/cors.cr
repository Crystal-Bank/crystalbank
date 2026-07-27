require "uri"

module CrystalBank
  module Server
    # Handles CORS for cross-origin requests from the dashboard to the API.
    # On OPTIONS preflight requests it short-circuits with 204.
    # On all other cross-origin requests it injects Access-Control-* headers
    # when the Origin matches the configured DASHBOARD_DOMAIN.
    #
    # /.well-known/* endpoints are public OAuth/JWKS discovery documents and
    # must be readable by any origin (e.g. a resource server fetching JWKS to
    # validate tokens). They get Access-Control-Allow-Origin: * with no
    # credentials header — the wildcard + credentials combination is invalid
    # per the Fetch spec. This is a distinct code path from the dashboard logic
    # so that future edits to one cannot accidentally affect the other.
    class CorsHandler
      include HTTP::Handler

      ALLOW_METHODS  = "GET, POST, PUT, PATCH, DELETE, OPTIONS"
      ALLOW_HEADERS  = "Authorization, Content-Type, X-Scope, idempotency_key"
      EXPOSE_HEADERS = "X-Request-ID"
      MAX_AGE        = "86400"

      def call(context : HTTP::Server::Context)
        path = context.request.path
        origin = context.request.headers["Origin"]?

        if path.starts_with?("/.well-known/")
          # Public discovery documents — open to any origin, no credentials
          h = context.response.headers
          h["Access-Control-Allow-Origin"] = "*"
          h["Access-Control-Allow-Methods"] = "GET, OPTIONS"
          h["Access-Control-Max-Age"] = MAX_AGE
        elsif origin && allowed_origin?(origin)
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
        return true if host == CrystalBank::Env.dashboard_domain
        # localhost is only allowed outside of production to prevent accidental
        # credential exposure via open CORS on a production deployment.
        return true if (host == "localhost" || host == "127.0.0.1") && CrystalBank::Env.environment != "production"
        false
      rescue
        false
      end
    end
  end
end
