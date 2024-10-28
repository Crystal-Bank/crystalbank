module CrystalBank
  module Env
    extend self

    def eventstore_uri : String
      @@eventstore_uri ||= ENV["EVENTSTORE_URI"]
    end

    def queue_uri : String
      @@queue_uri ||= ENV["QUEUE_URI"]
    end

    def git_hash : String
      @@git_hash ||= File.read("./REVISION.txt").strip
    end

    def environment : String
      @@environment ||= (ENV["ENVIRONMENT"]? || "development")
    end
  end
end
