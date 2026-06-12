# Shared codec + field utilities (no ES machinery)
require "./shared/bitmap"
require "./shared/fields/definitions"
require "./shared/fields/data_elements"
require "./shared/codec/message"
require "./shared/codec/decoder"
require "./shared/codec/encoder"

# Version-specific domains
require "./v1987/load"
require "./v1993/load"
