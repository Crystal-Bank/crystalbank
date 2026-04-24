module CrystalBank::Domains::Credentials
  module Queries
    class Credentials
      struct Credential
        include DB::Serializable
        include DB::Serializable::NonStrict

        @[DB::Field(key: "uuid")]
        getter user_id : UUID
        getter aggregate_version : Int64
        getter status : String
        getter password_hash : String?
        getter invitation_token_hash : String?
        getter invitation_expires_at : Time?
        getter reset_token_hash : String?
        getter reset_expires_at : Time?
        getter totp_encrypted_secret : String?
        getter totp_active : Bool
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def get(user_id : UUID) : Credential?
        @db.query_one?(
          "SELECT * FROM projections.user_credentials WHERE uuid = $1",
          args: [user_id],
          as: Credential
        )
      end
    end
  end
end
