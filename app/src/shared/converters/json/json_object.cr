module CrystalBank::Converters
  struct JsonObject(T)
    def self.from_rs(rs : DB::ResultSet) : T?
      r = rs.read
      return nil unless r.class == JSON::PullParser
      T.new(r.as(JSON::PullParser))
    end
  end
end
