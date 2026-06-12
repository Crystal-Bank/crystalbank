module CrystalBank::Domains::Cards::Iso8583::Shared
  # Data elements that are identical in both the 1987 and 1993 revisions.
  # Version-specific modules extend this map with overrides or additions.
  COMMON_DATA_ELEMENTS = {
     2 => FieldDefinition.new(2,  FieldEncoding::LLVAR,  19, "Primary Account Number (PAN)"),
     3 => FieldDefinition.new(3,  FieldEncoding::Fixed,   6, "Processing Code"),
     4 => FieldDefinition.new(4,  FieldEncoding::Fixed,  12, "Amount, Transaction"),
     7 => FieldDefinition.new(7,  FieldEncoding::Fixed,  10, "Transmission Date and Time"),
    11 => FieldDefinition.new(11, FieldEncoding::Fixed,   6, "Systems Trace Audit Number (STAN)"),
    12 => FieldDefinition.new(12, FieldEncoding::Fixed,   6, "Local Transaction Time"),
    13 => FieldDefinition.new(13, FieldEncoding::Fixed,   4, "Local Transaction Date"),
    14 => FieldDefinition.new(14, FieldEncoding::Fixed,   4, "Expiration Date"),
    22 => FieldDefinition.new(22, FieldEncoding::Fixed,   3, "Point of Service Entry Mode"),
    25 => FieldDefinition.new(25, FieldEncoding::Fixed,   2, "Point of Service Condition Code"),
    35 => FieldDefinition.new(35, FieldEncoding::LLVAR,  37, "Track 2 Data"),
    37 => FieldDefinition.new(37, FieldEncoding::Fixed,  12, "Retrieval Reference Number"),
    38 => FieldDefinition.new(38, FieldEncoding::Fixed,   6, "Authorization Identification Response"),
    39 => FieldDefinition.new(39, FieldEncoding::Fixed,   2, "Response Code"),
    41 => FieldDefinition.new(41, FieldEncoding::Fixed,   8, "Card Acceptor Terminal Identification"),
    42 => FieldDefinition.new(42, FieldEncoding::Fixed,  15, "Card Acceptor Identification Code"),
    43 => FieldDefinition.new(43, FieldEncoding::Fixed,  40, "Card Acceptor Name/Location"),
    49 => FieldDefinition.new(49, FieldEncoding::Fixed,   3, "Currency Code, Transaction"),
    60 => FieldDefinition.new(60, FieldEncoding::LLLVAR, 999, "Reserved Private"),
    63 => FieldDefinition.new(63, FieldEncoding::LLLVAR, 999, "Reserved Private"),
  } of Int32 => FieldDefinition
end
