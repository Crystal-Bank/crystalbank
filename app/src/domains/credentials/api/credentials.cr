module CrystalBank::Domains::Credentials
  module Api
    class CredentialsController < CrystalBank::Api::Base
      base "/auth"

      struct SetupPasswordRequest
        include JSON::Serializable

        getter user_id : UUID
        getter token : String
        getter password : String
      end

      struct ForgotPasswordRequest
        include JSON::Serializable

        getter email : String
      end

      struct ResetPasswordRequest
        include JSON::Serializable

        getter user_id : UUID
        getter token : String
        getter password : String
      end

      struct TotpConfirmRequest
        include JSON::Serializable

        getter code : String
      end

      struct TotpSetupResponse
        include JSON::Serializable

        getter secret : String
        getter uri : String

        def initialize(@secret : String, @uri : String)
        end
      end

      struct OkResponse
        include JSON::Serializable

        getter ok : Bool = true
      end

      # Complete password setup using the invitation token sent by email
      # Required permission: none
      @[AC::Route::POST("/setup_password", body: :r)]
      def setup_password(r : SetupPasswordRequest) : OkResponse
        Credentials::PasswordSetup::Commands::Request.new.call(r.user_id, r.token, r.password)
        OkResponse.new
      end

      # Request a password reset email
      # Required permission: none
      @[AC::Route::POST("/forgot_password", body: :r)]
      def forgot_password(r : ForgotPasswordRequest) : OkResponse
        Credentials::PasswordReset::Commands::Request.new.call(r.email)
        OkResponse.new
      end

      # Complete password reset using the token sent by email
      # Required permission: none
      @[AC::Route::POST("/reset_password", body: :r)]
      def reset_password(r : ResetPasswordRequest) : OkResponse
        Credentials::PasswordReset::Commands::Confirm.new.call(r.user_id, r.token, r.password)
        OkResponse.new
      end

      # Initiate TOTP setup — generates a secret and returns the otpauth URI
      # Required permission: write_credentials_totp_setup
      @[AC::Route::POST("/totp/setup")]
      def totp_setup : TotpSetupResponse
        authorized?("write_credentials_totp_setup", request_scope: false)
        user_id = context.user_id
        secret, uri = Credentials::Totp::Commands::Setup.new.call(user_id)
        TotpSetupResponse.new(secret: secret, uri: uri)
      end

      # Confirm TOTP by verifying a code — enables TOTP on the account
      # Required permission: write_credentials_totp_confirm
      @[AC::Route::POST("/totp/confirm", body: :r)]
      def totp_confirm(r : TotpConfirmRequest) : OkResponse
        authorized?("write_credentials_totp_confirm", request_scope: false)
        user_id = context.user_id
        Credentials::Totp::Commands::Confirm.new.call(user_id, r.code)
        OkResponse.new
      end
    end
  end
end
