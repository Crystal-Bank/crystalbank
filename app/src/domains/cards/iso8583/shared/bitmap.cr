module CrystalBank::Domains::Cards::Iso8583::Shared
  # Handles the primary (bits 1–64) and optional secondary (bits 65–128) bitmaps.
  # Bit 1 of the primary bitmap indicates whether a secondary bitmap is present.
  module Bitmap
    def self.decode(bytes : Bytes) : {Set(Int32), Int32}
      raise ArgumentError.new("Need at least 8 bytes for primary bitmap") if bytes.size < 8

      bits = Set(Int32).new
      read_bitmap(bytes, 0, bits)

      consumed = 8
      if bits.includes?(1)
        raise ArgumentError.new("Need 16 bytes for secondary bitmap") if bytes.size < 16
        read_bitmap(bytes, 8, bits)
        consumed = 16
      end

      {bits, consumed}
    end

    def self.encode(fields : Enumerable(Int32)) : Bytes
      has_secondary = fields.any? { |f| f > 64 }
      buf = Bytes.new(has_secondary ? 16 : 8, 0_u8)
      buf[0] |= 0x80_u8 if has_secondary # set bit 1 = secondary present

      fields.each do |bit|
        next if bit == 1 # bit 1 is the secondary-present flag, not a data element
        zero_based = bit - 1
        byte_idx = zero_based // 8
        bit_pos  = 7 - (zero_based % 8)
        buf[byte_idx] |= (1_u8 << bit_pos)
      end

      buf
    end

    private def self.read_bitmap(bytes : Bytes, offset : Int32, bits : Set(Int32))
      8.times do |byte_i|
        8.times do |bit_i|
          bit_number = offset * 8 + byte_i * 8 + bit_i + 1
          bits << bit_number if (bytes[offset + byte_i] & (0x80_u8 >> bit_i)) != 0
        end
      end
    end
  end
end
