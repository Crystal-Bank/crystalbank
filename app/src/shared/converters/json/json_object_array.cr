module CrystalBank::Converters
  # Like GenericArray but for types that include JSON::Serializable (structs/classes),
  # rather than types with a `.parse(String)` method (e.g. enums).
  struct JsonObjectArray(T)
    def self.from_rs(rs : DB::ResultSet) : Array(T)
      result = Array(T).new
      r = rs.read
      return result unless r.class == JSON::PullParser
      pull = r.as(JSON::PullParser)
      Array(T).from_json(pull.read_raw)
    end
  end
end
