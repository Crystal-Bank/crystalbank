# Application dependencies
require "action-controller"
require "action-controller/logger"
require "option_parser"

# Application code
require "../crystalbank"

# Load OpenAPI controller
require "./openapi"

# Server required after application controllers
require "action-controller/server"

require "./config"
require "./cli"

module Crystalbank
  module Server
    include Crystalbank::Server::Config
    include Crystalbank::Server::CLI

    # flag to indicate if we're outputting trace logs
    class_getter? trace : Bool = false

    # Registers callbacks for USR1 signal
    #
    # **`USR1`**
    # toggles `:trace` for _all_ `Log` instances
    # `namespaces`'s `Log`s to `:info` if `production` is `true`,
    # otherwise it is set to `:debug`.
    # `Log`'s not registered under `namespaces` are toggled to `default`
    #
    # ## Usage
    # - `$ kill -USR1 ${the_application_pid}`
    def self.register_severity_switch_signals : Nil
      # Allow signals to change the log level at run-time
      {% unless flag?(:win32) %}
        Signal::USR1.trap do |signal|
          @@trace = !@@trace
          level = @@trace ? ::Log::Severity::Trace : (IS_PRODUCTION ? ::Log::Severity::Info : ::Log::Severity::Debug)
          puts " > Log level changed to #{level}"
          ::Log.builder.bind "#{NAME}.*", level, LOG_BACKEND

          # Ignore standard behaviour of the signal
          signal.ignore

          # we need to re-register our interest in the signal
          register_severity_switch_signals
        end
      {% end %}
    end

    server = ActionController::Server.new(DEFAULT_PORT, DEFAULT_HOST)

    # (process_count < 1) == `System.cpu_count` but this is not always accurate
    # Clustering using processes, there is no forking once crystal threads drop
    server.cluster(DEFAULT_PROCESS_COUNT, "-w", "--workers") if DEFAULT_PROCESS_COUNT != 1

    {% if flag?(:win32) %}
      Process.on_interrupt do
        puts " > terminating gracefully"
        server.close
      end
    {% else %}
      terminate = Proc(Signal, Nil).new do |signal|
        puts " > terminating gracefully"
        spawn { server.close }
        signal.ignore
      end

      # Detect ctr-c to shutdown gracefully
      # Docker containers use the term signal
      Signal::INT.trap &terminate
      Signal::TERM.trap &terminate

      # Allow signals to change the log level at run-time
      # Turn on DEBUG level logging `kill -s USR1 %PID`
      register_severity_switch_signals
    {% end %}

    # Start the server
    server.run do
      puts "Listening on #{server.print_addresses} - Environment #{ENVIRONMENT}"
    end

    # Shutdown message
    puts "#{NAME} says goodnight!\n"
  end
end
