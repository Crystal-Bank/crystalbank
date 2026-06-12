module CrystalBank::Domains::Cards::Iso8583::V1987
  VERSION = 1987

  # MTI first-digit for this revision
  MTI_PREFIX = "0"

  # Fully resolved field map for this version — starts from common DEs and
  # applies any 1987-specific overrides defined in fields/data_elements.cr.
  FIELD_MAP = Shared::COMMON_DATA_ELEMENTS.merge(V1987_DATA_ELEMENTS)
end
