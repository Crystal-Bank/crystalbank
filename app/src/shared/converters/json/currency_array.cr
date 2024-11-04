module CrystalBank::Converters
  struct CurrencyArray
    def self.from_rs(rs : DB::ResultSet) : Array(CrystalBank::Types::Currency)
      result = Array(CrystalBank::Types::Currency).new

      r = rs.read
      return result unless r.class == JSON::PullParser

      pull = r.as(JSON::PullParser)

      pull.read_array do
        result << CrystalBank::Types::Currency.new(pull.read_string)
      end

      result
    end
  end
end
