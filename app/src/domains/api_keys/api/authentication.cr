module CrystalBank::Domains::ApiKeys
  module Api
    class Authentication < CrystalBank::Api::Base
      base "/oauth"

      struct Request
        include JSON::Serializable

        @[JSON::Field(description: "Grant type of the token request, always 'client_credentials'")]
        getter grant_type : String

        @[JSON::Field(description: "ID of the api key")]
        getter client_id : String

        @[JSON::Field(description: "Secret of the api key")]
        getter client_secret : String
      end

      struct Response
        include JSON::Serializable

        getter token : String
        getter token_type = "Bearer"

        def initialize(@token : String)
        end
      end

      # Authenticate an API client
      # Authenticate an API client
      #
      # Required permission:
      # - none
      @[AC::Route::POST("/token", body: :r)]
      def authenticate(r : Request) : Response
        raise CrystalBank::Exception::Authentication.new("invalid grant_type #{r.grant_type}") unless r.grant_type == "client_credentials"

        token = ::ApiKeys::Authentication::Commands::Request.new.call(r.client_id, r.client_secret)

        Response.new(token)
      end
    end
  end
end
