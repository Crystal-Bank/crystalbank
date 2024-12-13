require "./load"

module CrystalBank
  {% begin %}
    VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
  {% end %}

  def self.print_verbose(title, message)
    puts
    puts "---------------------------------------------"
    puts "----------------- #{title} ------------------"
    puts message
    puts "---------------------------------------------"
    puts "---------------------------------------------"
    puts
  end
end
