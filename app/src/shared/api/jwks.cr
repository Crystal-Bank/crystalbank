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
        getter x : String
        getter y : String

        def initialize(@kty, @use, @alg, @crv, @x, @y)
        end
      end

      struct JWKSResponse
        include JSON::Serializable

        getter keys : Array(JWK)

        def initialize(@keys : Array(JWK))
        end
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

        # For a P-256 SubjectPublicKeyInfo DER (91 bytes), the uncompressed EC
        # point (0x04 || x || y) starts at byte 26. x is bytes 27-58, y is 59-90.
        x = Base64.urlsafe_encode(der[27, 32], false)
        y = Base64.urlsafe_encode(der[59, 32], false)

        JWKSResponse.new([
          JWK.new(kty: "EC", use: "sig", alg: "ES256", crv: "P-256", x: x, y: y),
        ])
      end
    end
  end
end
