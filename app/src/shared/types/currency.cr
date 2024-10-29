module CrystalBank::Types
  struct Currency
    @@currencies = YAML.parse(CrystalBank::Types.currencies_yaml)["currencies"].as_a
    @@supported_currencies = YAML.parse(CrystalBank::Types.currencies_yaml)["supported_currencies"].as_a

    def self.valid?(value : String) : Bool
      @@currencies.includes?(value)
    end

    def self.supported?(value : String) : Bool
      @@supported_currencies.includes?(value)
    end

    def initialize(value : String)
      @value = value
      validate!
    end

    def to_s
      @value
    end

    private def supported!
      raise CrystalBank::Exception::InvalidArgument.new("Currency not supported '#{@value}'. Supported currencies are: [#{supported_currencies}]") unless self.classsupported?(@value)
    end

    private def supported_currencies : String
      s = @@supported_currencies.map { |x| x.to_s }
      s.join(", ")
    end

    private def validate!
      raise CrystalBank::Exception::InvalidArgument.new("Currency invalid '#{@value}'. Valid currencies are: [#{valid_currencies}]") unless self.class.valid?(@value)
    end

    private def valid_currencies : String
      s = @@currencies.map { |x| x.to_s }
      s.join(", ")
    end
  end
end
