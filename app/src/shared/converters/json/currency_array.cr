module CrystalBank::Converters
  struct CurrencyArray(T)
    def self.from_rs(rs : DB::ResultSet) : Array(T)
      result = Array(T).new
      r = rs.read
      return result unless r.class == JSON::PullParser
      pull = r.as(JSON::PullParser)
      pull.read_array do
        result << T.parse(pull.read_string)
      end
      result
    end
  end
end
