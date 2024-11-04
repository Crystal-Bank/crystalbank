# TODO: Decide if the account type strongly belongs to the accounts domain
module CrystalBank::Types
  struct AccountType
    @@types = YAML.parse(CrystalBank::Types.account_types_yaml)["account_types"].as_a

    def self.valid?(value : String) : Bool
      @@types.includes?(value)
    end

    def initialize(value : String)
      @value = value
      validate!
    end

    # Initializes a new account type from a JSON::PullParser
    def initialize(parser : JSON::PullParser)
      @value = parser.read_string
      validate!
    end

    # Converts the account type to a json element
    def to_json(json : JSON::Builder) : Nil
      json.string(@value)
    end

    # Returns the account type as a string
    def to_s
      @value
    end

    private def validate! : AccountType
      raise CrystalBank::Exception::InvalidArgument.new("Account type not supported '#{@value}'. Supported types are: [#{supported_types}]") unless self.class.valid?(@value)
      self
    end

    private def supported_types : String
      s = @@types.map { |x| x.to_s }
      s.join(", ")
    end
  end
end
