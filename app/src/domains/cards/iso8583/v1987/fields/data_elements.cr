module CrystalBank::Domains::Cards::Iso8583::V1987
  # 1987-revision data elements that differ from or extend the common set.
  V1987_DATA_ELEMENTS = {
    # DE 23 – Card Sequence Number is present in 1987 as a 3-digit fixed field.
    23 => Shared::FieldDefinition.new(23, Shared::FieldEncoding::Fixed, 3, "Card Sequence Number"),
    # DE 52 – Encrypted PIN Data (8-byte binary, represented as LLLLVAR here for transport)
    52 => Shared::FieldDefinition.new(52, Shared::FieldEncoding::LLLLVAR, 8, "Personal Identification Number (PIN) Data"),
  } of Int32 => Shared::FieldDefinition
end
