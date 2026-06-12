module CrystalBank::Domains::Cards::Iso8583::V1993
  # 1993-revision data elements that differ from or extend the common set.
  # Notable 1993 additions: DE 90 (original data elements), DE 95 (replacement amounts).
  V1993_DATA_ELEMENTS = {
    23  => Shared::FieldDefinition.new(23,  Shared::FieldEncoding::Fixed,   3, "Card Sequence Number"),
    52  => Shared::FieldDefinition.new(52,  Shared::FieldEncoding::LLLLVAR, 8, "Personal Identification Number (PIN) Data"),
    90  => Shared::FieldDefinition.new(90,  Shared::FieldEncoding::Fixed,  42, "Original Data Elements"),
    95  => Shared::FieldDefinition.new(95,  Shared::FieldEncoding::Fixed,  42, "Replacement Amounts"),
    102 => Shared::FieldDefinition.new(102, Shared::FieldEncoding::LLVAR,  28, "Account Identification 1"),
    103 => Shared::FieldDefinition.new(103, Shared::FieldEncoding::LLVAR,  28, "Account Identification 2"),
  } of Int32 => Shared::FieldDefinition
end
