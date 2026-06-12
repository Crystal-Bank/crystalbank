module CrystalBank::Domains::Cards::Iso8583::Shared
  # Encodes a +Message+ (mti + fields hash) back to wire bytes.
  # The caller supplies the field map for the relevant version.
  class Encoder
    def initialize(@field_map : Hash(Int32, FieldDefinition))
    end

    def encode(msg : Message) : Bytes
      present = msg.fields.keys.sort
      bitmap_bytes = Bitmap.encode(present)

      io = IO::Memory.new
      io.write(msg.mti.to_slice)
      io.write(bitmap_bytes)

      present.each do |de|
        defn = @field_map[de]? || raise ArgumentError.new("Unknown DE #{de}")
        encode_field(io, defn, msg.fields[de])
      end

      io.to_slice
    end

    private def encode_field(io : IO, defn : FieldDefinition, value : String)
      case defn.encoding
      in .fixed?
        padded = value.ljust(defn.max_length)[0, defn.max_length]
        io.write(padded.to_slice)
      in .llvar?
        io.write("%02d" % value.bytesize)
        io.write(value.to_slice)
      in .lllvar?
        io.write("%03d" % value.bytesize)
        io.write(value.to_slice)
      in .llllvar?
        io.write("%04d" % value.bytesize)
        io.write(value.to_slice)
      end
    end
  end
end
