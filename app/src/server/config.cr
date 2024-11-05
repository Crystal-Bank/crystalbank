module CrystalBank
  module Server
    module Config
      NAME = "CrystalBank"
      {% begin %}
        VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
      {% end %}

      Log         = ::Log.for(NAME)
      LOG_BACKEND = ActionController.default_backend(formatter: ActionController.json_formatter)

      ENVIRONMENT   = CrystalBank::Env.environment
      IS_PRODUCTION = (ENVIRONMENT == "production")

      DEFAULT_PORT          = CrystalBank::Env.server_port
      DEFAULT_HOST          = CrystalBank::Env.server_host
      DEFAULT_PROCESS_COUNT = CrystalBank::Env.server_process_count
      API_DOMAIN            = CrystalBank::Env.api_domain

      # Configure logging (backend defined in constants.cr)
      if IS_PRODUCTION
        log_level = ::Log::Severity::Info
        ::Log.setup "*", :warn, LOG_BACKEND
      else
        log_level = ::Log::Severity::Debug
        ::Log.setup "*", :info, LOG_BACKEND
      end
      ::Log.builder.bind "action-controller.*", log_level, LOG_BACKEND
      ::Log.builder.bind "#{NAME}.*", log_level, LOG_BACKEND

      # Filter out sensitive params that shouldn't be logged
      filter_params = ["password", "bearer_token"]
      keeps_headers = ["X-Request-ID"]

      # Add handlers that should run before your application
      ActionController::Server.before(
        ActionController::ErrorHandler.new(IS_PRODUCTION, keeps_headers),
        ActionController::LogHandler.new(filter_params),
        HTTP::CompressHandler.new
      )
    end
  end
end
