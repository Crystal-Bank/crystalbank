module CrystalBank
  module Env
    extend self

    @@application_name : String?
    @@api_domain : String?
    @@api_base_url : String?
    @@dashboard_domain : String?
    @@server_environment : String?
    @@server_port : Int32?
    @@server_host : String?
    @@server_process_count : Int32?

    def application_name
      @@application_name ||= ENV["APPLICATION_NAME"]? || "crystalbank"
    end

    def api_domain : String
      @@api_domain ||= ENV["API_DOMAIN"]? || "api.crystalbank.xyz"
    end

    def api_base_url : String
      @@api_base_url ||= ENV["API_BASE_URL"]? || "https://#{api_domain}"
    end

    def dashboard_domain : String
      @@dashboard_domain ||= ENV["DASHBOARD_DOMAIN"]? || "dashboard.crystalbank.xyz"
    end

    def api_domains : Array(String)
      @@api_domains = ENV["API_DOMAINS"]? ? ENV["API_DOMAINS"].split(",") : ["https://api.crystalbank.xyz", "http://localhost:4000"]
    end

    def environment : String
      @@environment ||= (ENV["ENVIRONMENT"]? || "development")
    end

    def eventstore_uri : String
      @@eventstore_uri ||= ENV["EVENTSTORE_URI"]
    end

    def git_hash : String
      @@git_hash ||= File.read("./REVISION.txt").strip
    end

    def projection_database_uri
      @@projection_database_uri ||= ENV["PROJECTION_DB_URI"]
    end

    def queue_uri : String
      @@queue_uri ||= ENV["QUEUE_URI"]
    end

    def server_port : Int32
      @@server_port ||= (ENV["SERVER_PORT"]? || 3000).to_i
    end

    def server_host : String
      "0.0.0.0"
    end

    def server_process_count : Int32
      @@server_process_count ||= (ENV["SERVER_PROCESS_COUNT"]? || 1).to_i
    end

    def jwt_private_key : String
      @@jwt_priv_key ||= ENV["JWT_PRIVATE_KEY"]
    end

    def jwt_public_key : String
      @@jwt_pub_key ||= ENV["JWT_PUBLIC_KEY"]
    end

    def jwt_public_key_uri : String
      @@jwt_pub_key_uri ||= ENV["JWT_PUBLIC_KEY_URI"]? || "https://api.crystalbank.xyz"
    end

    def jwt_ttl : Int32
      3600
    end

    def sepa_settlement_account_id : UUID
      UUID.new(ENV["SEPA_SETTLEMENT_ACCOUNT_ID"]? || "00000000-0000-0000-0000-900000000001")
    end

    @@smtp_host : String?
    @@smtp_port : Int32?
    @@smtp_from : String?
    @@smtp_username : String?
    @@smtp_password : String?
    @@smtp_tls : Bool?
    @@totp_encryption_key : String?
    @@invitation_token_ttl : Int32?
    @@password_reset_token_ttl : Int32?

    def smtp_host : String
      @@smtp_host ||= ENV["SMTP_HOST"]? || "mailhog"
    end

    def smtp_port : Int32
      @@smtp_port ||= (ENV["SMTP_PORT"]? || "1025").to_i
    end

    def smtp_from : String
      @@smtp_from ||= ENV["SMTP_FROM"]? || "noreply@crystalbank.xyz"
    end

    def smtp_username : String?
      @@smtp_username ||= ENV["SMTP_USERNAME"]?.presence
    end

    def smtp_password : String?
      @@smtp_password ||= ENV["SMTP_PASSWORD"]?.presence
    end

    def smtp_tls : Bool
      (ENV["SMTP_TLS"]? || "false") == "true"
    end

    def totp_encryption_key : String
      @@totp_encryption_key ||= ENV["TOTP_ENCRYPTION_KEY"]? || "0" * 64
    end

    def invitation_token_ttl : Int32
      @@invitation_token_ttl ||= (ENV["INVITATION_TOKEN_TTL"]? || "604800").to_i
    end

    def password_reset_token_ttl : Int32
      @@password_reset_token_ttl ||= (ENV["PASSWORD_RESET_TOKEN_TTL"]? || "3600").to_i
    end
  end
end
