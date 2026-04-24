module CrystalBank::Domains::Credentials
  module Api
    class Authentication < CrystalBank::Api::Base
      base "/auth"

      struct LoginRequest
        include JSON::Serializable

        getter email : String
        getter password : String
        getter totp_code : String?
      end

      struct LoginResponse
        include JSON::Serializable

        getter token : String
        getter token_type = "Bearer"

        def initialize(@token : String)
        end
      end

      @[AC::Route::Exception(Credentials::Authentication::Commands::Request::TotpRequired, status_code: HTTP::Status::PRECONDITION_REQUIRED)]
      def totp_required_response(error : Credentials::Authentication::Commands::Request::TotpRequired) : ErrorResponse
        ErrorResponse.new(UUID.v7, "totp_required", Time.utc, "TotpRequired")
      end

      # Login with email and password (optionally with TOTP code)
      # Required permission: none
      @[AC::Route::POST("/login", body: :r)]
      def login(r : LoginRequest) : LoginResponse
        token = Credentials::Authentication::Commands::Request.new.call(r.email, r.password, r.totp_code)
        LoginResponse.new(token)
      end
    end
  end
end
