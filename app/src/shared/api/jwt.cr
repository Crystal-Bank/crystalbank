module CrystalBank
  module Api
    struct JWT
      include JSON::Serializable

      # Data structure to hold user-specific JWT information
      struct JWTData
        include JSON::Serializable

        getter roles : Array(UUID) # Roles assigned to the user
        getter user : UUID         # User ID associated with the JWT

        # Initialize JWTData with user ID and roles

        def initialize(@roles : Array(UUID), @user : UUID)
        end
      end

      # JWT properties
      getter exp : Int64    # Expires at
      getter iat : Int64    # Issued at
      getter iss : String   # Issuer
      getter jti : UUID     # JWT id
      getter data : JWTData # JWTData instance containing user information

      def initialize(roles : Array(UUID), user_id : UUID)
        @exp = Time.utc.to_unix + CrystalBank::Env.jwt_ttl
        @iat = Time.utc.to_unix
        @iss = "CrystalBank"
        @jti = UUID.random

        @data = JWTData.new(roles, user_id)
      end
    end
  end
end
