module CrystalBank::Types
  struct Currency
    @@currencies = YAML.parse(CrystalBank::Types.currencies_yaml)["currencies"].as_a
    @@supported_currencies = YAML.parse(CrystalBank::Types.currencies_yaml)["supported_currencies"].as_a

    # Checks the validity of the provided symbol
    def self.valid?(symbol : String) : Bool
      @@currencies.includes?(symbol)
    end

    # Checks if the provided symbol is supported
    def self.supported?(symbol : String) : Bool
      @@supported_currencies.includes?(symbol)
    end

    # Initializes a new currency with a string
    def initialize(symbol : String)
      @symbol = symbol
      validate!
    end

    # Initializes a new currency from a JSON::PullParser
    def initialize(parser : JSON::PullParser)
      @symbol = parser.read_string
      validate!
    end

    # Enforces that the currency is supported by the system
    def supported! : Currency
      raise CrystalBank::Exception::InvalidArgument.new("Currency not supported '#{@symbol}'. Supported currencies are: [#{supported_currencies}]") unless self.class.supported?(@symbol)
      self
    end

    # Converts the currency to a json element
    def to_json(json : JSON::Builder) : Nil
      json.string(@symbol)
    end

    # Returns the symbol as a string
    def to_s : String
      @symbol
    end

    private def supported_currencies : String
      s = @@supported_currencies.map { |x| x.to_s }
      s.join(", ")
    end

    private def validate!
      raise CrystalBank::Exception::InvalidArgument.new("Currency invalid '#{@symbol}'. Valid currencies are: [#{valid_currencies}]") unless self.class.valid?(@symbol)
    end

    private def valid_currencies : String
      s = @@currencies.map { |x| x.to_s }
      s.join(", ")
    end
  end
end
