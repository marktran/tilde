# -*- Mode: Ruby; -*-
# .irbrc : Mark Tran <mark@nirv.net>

require 'rubygems'

require 'irb/completion'
require 'yaml'
require 'pp'

IRB.conf[:PROMPT_MODE] = :SIMPLE
IRB.conf[:AUTO_INDENT]= true

# start wirble (with color)
begin
  require 'wirble'
  Wirble.init
  Wirble.colorize unless IRB.conf[:PROMPT_MODE] == :INF_RUBY
rescue LoadError
end
