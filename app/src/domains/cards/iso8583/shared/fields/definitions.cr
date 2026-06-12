module CrystalBank::Domains::Cards::Iso8583::Shared
  # Describes how a data element is encoded on the wire.
  enum FieldEncoding
    Fixed    # length is always exactly `length` bytes
    LLVAR    # 2-digit ASCII length prefix, up to 99 bytes
    LLLVAR   # 3-digit ASCII length prefix, up to 999 bytes
    LLLLVAR  # 4-digit ASCII length prefix, up to 9999 bytes (binary data)
  end

  # A single data element descriptor.
  record FieldDefinition,
    number : Int32,
    encoding : FieldEncoding,
    max_length : Int32,
    description : String
end
