module CrystalBank
  module Env
    extend self

    @@api_domain : String?
    @@server_environment : String?
    @@server_port : Int32?
    @@server_host : String?
    @@server_process_count : Int32?

    def api_domain : String
      @@api_domain ||= ENV["API_DOMAIN"]? || "https://api.crystalbank.xyz"
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

    def jwt_ttl : Int32
      3600
    end
  end
end
