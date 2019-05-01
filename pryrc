# Make print awesome
begin
  require 'awesome_print'
  Pry.config.print = proc { |output, value| output.puts value.ai }
  AwesomePrint.defaults = { indent: -2 }
  AwesomePrint.pry!
rescue LoadError => err
  puts 'no awesome_print :('
end

if ENV['RAILS_ENV'] || defined?(Rails)
  red     = "\033[0;31m"
  yellow  = "\033[0;33m"
  blue    = "\033[0;34m"
  default = "\033[0;39m"

  color = Rails.env =~ /production/ ? red : blue
  Pry.config.prompt_name = "#{yellow}#{File.basename Rails.root}#{default} - #{color}#{Rails.env}#{default} "
end

def pbcopy(input)
  str = input.to_s
  IO.popen('pbcopy', 'w') { |f| f << str }
  str
end

def pbpaste
  `pbpaste`
end
