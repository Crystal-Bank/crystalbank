module CrystalBank::Domains::Credentials
  module Projections
    class Credentials < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename = 'user_credentials');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."user_credentials" (
            "id"                    SERIAL PRIMARY KEY,
            "uuid"                  UUID NOT NULL,
            "aggregate_version"     int8 NOT NULL,
            "status"                varchar NOT NULL,
            "password_hash"         varchar,
            "invitation_token_hash" varchar,
            "invitation_expires_at" timestamp,
            "reset_token_hash"      varchar,
            "reset_expires_at"      timestamp,
            "totp_encrypted_secret" varchar,
            "totp_active"           boolean NOT NULL DEFAULT false
          );
        )
        m << %(CREATE UNIQUE INDEX user_credentials_uuid_idx ON "projections"."user_credentials"(uuid);)
        m.each { |s| @projection_database.exec s }
      end

      def apply(event : ::Credentials::Invitation::Events::Sent)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        body = event.body.as(::Credentials::Invitation::Events::Sent::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          existing = cnn.query_one?("SELECT uuid FROM projections.user_credentials WHERE uuid = $1", aggregate_id, as: UUID)
          if existing
            cnn.exec %(
              UPDATE "projections"."user_credentials"
              SET invitation_token_hash=$1, invitation_expires_at=$2, aggregate_version=$3
              WHERE uuid=$4
            ), body.token_hash, body.expires_at, aggregate_version, aggregate_id
          else
            cnn.exec %(
              INSERT INTO "projections"."user_credentials"
                (uuid, aggregate_version, status, invitation_token_hash, invitation_expires_at)
              VALUES ($1, $2, $3, $4, $5)
            ), aggregate_id, aggregate_version, "pending_setup", body.token_hash, body.expires_at
          end
        end
      end

      def apply(event : ::Credentials::PasswordSetup::Events::Completed)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        body = event.body.as(::Credentials::PasswordSetup::Events::Completed::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE "projections"."user_credentials"
            SET password_hash=$1, status=$2, invitation_token_hash=NULL, invitation_expires_at=NULL, aggregate_version=$3
            WHERE uuid=$4
          ), body.password_hash, "active", aggregate_version, aggregate_id
        end
      end

      def apply(event : ::Credentials::PasswordReset::Events::Requested)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        body = event.body.as(::Credentials::PasswordReset::Events::Requested::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE "projections"."user_credentials"
            SET reset_token_hash=$1, reset_expires_at=$2, aggregate_version=$3
            WHERE uuid=$4
          ), body.token_hash, body.expires_at, aggregate_version, aggregate_id
        end
      end

      def apply(event : ::Credentials::PasswordReset::Events::Confirmed)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        body = event.body.as(::Credentials::PasswordReset::Events::Confirmed::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE "projections"."user_credentials"
            SET password_hash=$1, reset_token_hash=NULL, reset_expires_at=NULL, aggregate_version=$2
            WHERE uuid=$3
          ), body.password_hash, aggregate_version, aggregate_id
        end
      end

      def apply(event : ::Credentials::Totp::Events::SetupInitiated)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        body = event.body.as(::Credentials::Totp::Events::SetupInitiated::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE "projections"."user_credentials"
            SET totp_encrypted_secret=$1, totp_active=false, aggregate_version=$2
            WHERE uuid=$3
          ), body.encrypted_secret, aggregate_version, aggregate_id
        end
      end

      def apply(event : ::Credentials::Totp::Events::Enabled)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE "projections"."user_credentials"
            SET totp_active=true, aggregate_version=$1
            WHERE uuid=$2
          ), aggregate_version, aggregate_id
        end
      end
    end
  end
end
