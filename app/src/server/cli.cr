module CrystalBank
  module Server
    module CLI
      docs = nil
      docs_file = nil

      # Command line options
      OptionParser.parse(ARGV.dup) do |parser|
        parser.banner = "Usage: #{PROGRAM_NAME} [arguments]"

        parser.on("-b HOST", "--bind=HOST", "Specifies the server host") { |h| host = h }
        parser.on("-p PORT", "--port=PORT", "Specifies the server port") { |p| port = p.to_i }

        parser.on("-w COUNT", "--workers=COUNT", "Specifies the number of processes to handle requests") do |w|
          process_count = w.to_i
        end

        parser.on("-r", "--routes", "List the application routes") do
          ActionController::Server.print_routes
          exit 0
        end

        parser.on("-v", "--version", "Display the application version") do
          puts "#{NAME} v#{VERSION}"
          exit 0
        end

        parser.on("-c URL", "--curl=URL", "Perform a basic health check by requesting the URL") do |url|
          begin
            response = HTTP::Client.get url
            exit 0 if (200..499).includes? response.status_code
            puts "health check failed, received response code #{response.status_code}"
            exit 1
          rescue error
            error.inspect_with_backtrace(STDOUT)
            exit 2
          end
        end

        parser.on("-d", "--docs", "Outputs OpenAPI documentation for this service") do
          docs = ActionController::OpenAPI.generate_open_api_docs(
            title: NAME,
            version: VERSION,
            description: "App description for OpenAPI docs"
          ).merge(NamedTuple.new(servers: [{url: API_DOMAIN}])).to_json

          parser.on("-f FILE", "--file=FILE", "Save the docs to a file") do |file|
            docs_file = file
          end
        end

        parser.on("-h", "--help", "Show this help") do
          puts parser
          exit 0
        end
      end

      if docs
        File.write(docs_file.as(String), docs) if docs_file
        puts docs_file ? "OpenAPI written to: #{docs_file}" : docs
        exit 0
      end
    end
  end
end
