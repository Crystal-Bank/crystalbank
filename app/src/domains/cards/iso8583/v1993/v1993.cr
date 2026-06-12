module CrystalBank::Domains::Cards::Iso8583::V1993
  VERSION = 1993

  MTI_PREFIX = "1"

  FIELD_MAP = Shared::COMMON_DATA_ELEMENTS.merge(V1993_DATA_ELEMENTS)
end
