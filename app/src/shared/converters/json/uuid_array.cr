module CrystalBank::Converters
  struct UUIDArray
    def self.from_rs(rs : DB::ResultSet) : Array(UUID)
      result = Array(UUID).new
      r = rs.read
      return result unless r.class == JSON::PullParser
      pull = r.as(JSON::PullParser)
      pull.read_array do
        result << UUID.new(pull.read_string)
      end
      result
    end
  end
end
