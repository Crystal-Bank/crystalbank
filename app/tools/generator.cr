require "option_parser"

directories = [
  "aggregates",
  "api",
  "api/concerns",
  "commands",
  "commands/<<process>>",
  "events",
  "events/<<process>>",
  "projections",
  "queries",
  "repositories",
]

files = [
  "<<domain>>.cr",
  "<<spec>>/queries/<<domain>>_spec.cr",
  "<<spec>>/aggregates/<<process>>_spec.cr",
  "<<spec>>/aggregates/aggregate_spec.cr",
  "<<spec>>/api/<<domain>>_spec.cr",
  "<<spec>>/commands/<<process>>/request_spec.cr",
  "<<spec>>/events/<<process>>/requested_spec.cr",
  "<<spec>>/projections/<<domain>>_spec.cr",
  "aggregates/<<process>>.cr",
  "aggregates/aggregate.cr",
  "api/<<domain>>.cr",
  "api/concerns/requests.cr",
  "api/concerns/responses.cr",
  "commands/<<process>>/request.cr",
  "events/<<process>>/requested.cr",
  "load.cr",
  "projections/<<domain>>.cr",
  "queries/<<domain>>.cr",
]

domain : String? = nil
process : String? = nil

OptionParser.parse do |parser|
  parser.banner = "Usage: generate [subcommand] [arguments]"
  parser.on("-d DOMAIN", "--domain=DOMAIN", "Define name of the new domain") do |d|
    domain = d
  end
  parser.on("-p PROCESS", "--process=PROCESS", "Define name of a process") do |p|
    process = p
  end
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

unless domain
  puts "!!! No domain defined - use -d DOMAIN"
  exit
end
domain_folder = ["src", "domains", domain].join("/")
domain_spec_folder = ["spec", "domains", domain].join("/")

directories.each do |d|
  next if d.includes?("<<process>>") && process.nil?
  d_name = d.gsub("<<process>>", process)

  src_directory = [domain_folder, d_name].join("/")
  src_spec_directory = [domain_spec_folder, d_name].join("/")

  Dir.mkdir_p(domain_spec_folder) unless File.exists?(domain_spec_folder)
  Dir.mkdir_p(src_directory) unless File.exists?(src_directory)
  Dir.mkdir_p(src_spec_directory) unless File.exists?(src_spec_directory)
end

files.each do |f|
  next if f.includes?("<<process>>") && process.nil?
  f_name = f.gsub("<<domain>>", domain).gsub("<<process>>", process)

  file = [domain_spec_folder, f_name].join("/")

  file = if f.includes?("<<spec>>")
           # Test file
           clean_f_name = f_name.gsub("<<spec>>/", "")
           [domain_spec_folder, clean_f_name].join("/")
         else
           # Generate code file
           [domain_folder, f_name].join("/")
         end

  unless File.exists?(file)
    puts file
    File.touch(file)
  end
end
