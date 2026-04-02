require "openssl"

ec_key = OpenSSL::EC::Key.new("prime256v1")

private_key = ec_key.to_pem
public_key = ec_key.public_key.to_pem

puts "=== JWT ES256 Key Pair ==="
puts ""
puts "--- Private Key (JWT_PRIVATE_KEY) ---"
puts private_key
puts "--- Public Key (JWT_PUBLIC_KEY) ---"
puts public_key
puts ""
puts "Set environment variables:"
puts %(JWT_PRIVATE_KEY="#{private_key.gsub("\n", "\\n")}")
puts %(JWT_PUBLIC_KEY="#{public_key.gsub("\n", "\\n")}")
