require "openssl_ext"

key = OpenSSL::PKey::EC.new(256)

puts key.to_pem
puts key.public_key.to_pem
