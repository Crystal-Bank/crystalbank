module CrystalBank::Converters
  struct StringArray
    def self.from_rs(rs : DB::ResultSet) : Array(String)
      result = Array(String).new
      r = rs.read
      return result unless r.class == JSON::PullParser
      pull = r.as(JSON::PullParser)
      pull.read_array do
        result << pull.read_string
      end
      result
    end
  end
end
