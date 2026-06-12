module CrystalBank::Domains::Cards::Iso8583::Shared
  # Decodes a raw ISO 8583 byte stream into a +Message+.
  # The caller supplies the field map for the relevant version.
  class Decoder
    def initialize(@field_map : Hash(Int32, FieldDefinition))
    end

    def decode(raw : Bytes) : Message
      raise ArgumentError.new("Message too short") if raw.size < 4

      mti = String.new(raw[0, 4])
      bitmap_bits, consumed = Bitmap.decode(raw[4..])
      offset = 4 + consumed

      fields = Hash(Int32, String).new

      bitmap_bits.each do |de|
        next if de == 1 # secondary bitmap presence flag, not a data element
        defn = @field_map[de]? || raise ArgumentError.new("Unknown DE #{de}")
        value, read = decode_field(defn, raw, offset)
        fields[de] = value
        offset += read
      end

      Message.new(mti: mti, fields: fields)
    end

    private def decode_field(defn : FieldDefinition, raw : Bytes, offset : Int32) : {String, Int32}
      case defn.encoding
      in .fixed?
        len = defn.max_length
        {String.new(raw[offset, len]), len}
      in .llvar?
        len = String.new(raw[offset, 2]).to_i
        {String.new(raw[offset + 2, len]), 2 + len}
      in .lllvar?
        len = String.new(raw[offset, 3]).to_i
        {String.new(raw[offset + 3, len]), 3 + len}
      in .llllvar?
        len = String.new(raw[offset, 4]).to_i
        {String.new(raw[offset + 4, len]), 4 + len}
      end
    end
  end
end
