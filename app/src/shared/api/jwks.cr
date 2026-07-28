require "base64"

module CrystalBank
  module Api
    class JWKS < CrystalBank::Api::Base
      base "/.well-known"

      struct JWK
        include JSON::Serializable

        getter kty : String
        getter use : String
        getter alg : String
        getter crv : String
        getter kid : String
        getter x : String
        getter y : String

        def initialize(@kty, @use, @alg, @crv, @kid, @x, @y)
        end
      end

      struct JWKSResponse
        include JSON::Serializable

        getter keys : Array(JWK)

        def initialize(@keys : Array(JWK))
        end
      end

      struct AuthorizationServerMetadata
        include JSON::Serializable

        getter issuer : String
        getter jwks_uri : String
        getter token_endpoint : String
        getter grant_types_supported : Array(String)
        getter response_types_supported : Array(String)
        getter token_endpoint_auth_methods_supported : Array(String)
        getter scopes_supported : Array(String)

        def initialize(
          @issuer,
          @jwks_uri,
          @token_endpoint,
          @grant_types_supported,
          @response_types_supported,
          @token_endpoint_auth_methods_supported,
          @scopes_supported,
        )
        end
      end

      # RFC 8414 Authorization Server Metadata
      # Returns the OAuth 2.0 authorization server metadata document.
      # CrystalBank only supports client_credentials — no authorization endpoint,
      # no ID tokens, so openid-configuration would be a false contract.
      #
      # Required permission:
      # - none
      @[AC::Route::GET("/oauth-authorization-server")]
      def authorization_server_metadata : AuthorizationServerMetadata
        issuer = CrystalBank::Env.issuer
        AuthorizationServerMetadata.new(
          issuer: issuer,
          jwks_uri: "#{issuer}/.well-known/jwks.json",
          token_endpoint: "#{issuer}/oauth/token",
          grant_types_supported: ["client_credentials"],
          response_types_supported: [] of String,
          token_endpoint_auth_methods_supported: ["client_secret_basic", "client_secret_post"],
          scopes_supported: CrystalBank::Permissions.values.map(&.to_s)
        )
      end

      # JWKS
      # Returns the public JSON Web Key Set for JWT validation
      #
      # Required permission:
      # - none
      @[AC::Route::GET("/jwks.json")]
      def jwks : JWKSResponse
        pem = CrystalBank::Env.jwt_public_key

        # Strip PEM header/footer and whitespace, then base64-decode to DER
        body = pem
          .gsub("-----BEGIN PUBLIC KEY-----", "")
          .gsub("-----END PUBLIC KEY-----", "")
          .gsub("\\n", "")
          .gsub("\n", "")
          .strip

        der = Base64.decode(body)

        # A P-256 SubjectPublicKeyInfo DER must be exactly 91 bytes. If this
        # raises, a non-P-256 key is configured and the x/y slices below would
        # produce garbage coordinates.
        raise "unexpected DER length: #{der.size}" unless der.size == 91

        # Uncompressed EC point (0x04 || x || y) starts at byte 26.
        # x is bytes 27-58, y is 59-90.
        x = Base64.urlsafe_encode(der[27, 32], false)
        y = Base64.urlsafe_encode(der[59, 32], false)

        kid = CrystalBank::Env.jwt_key_id

        JWKSResponse.new([
          JWK.new(kty: "EC", use: "sig", alg: "ES256", crv: "P-256", kid: kid, x: x, y: y),
        ])
      end
    end
  end
end
