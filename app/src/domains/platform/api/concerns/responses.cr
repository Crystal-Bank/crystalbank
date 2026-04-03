module CrystalBank::Domains::Platform
  module Api
    module Responses
      struct Credential
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "API key client ID")]
        getter client_id : UUID

        @[JSON::Field(description: "API key client secret (only returned once)")]
        getter client_secret : String

        def initialize(@client_id : UUID, @client_secret : String); end
      end

      struct ResetResponse
        include JSON::Serializable

        @[JSON::Field(description: "Credentials for the Super Admin user")]
        getter super_admin : Credential

        @[JSON::Field(description: "Credentials for the Approver user")]
        getter approver : Credential

        def initialize(@super_admin : Credential, @approver : Credential); end
      end
    end
  end
end
