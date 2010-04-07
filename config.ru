#############################################################################
#--
# Copyright (c) 2009-2010 Colder <cncolder@gmail.com>.
#   Released under the MIT license.
#++
#############################################################################

require 'net/http'

VERSION = '0.1.0'

TWITTER = URI('http://twitter.com')

map '/' do
  run lambda { |env|
    case env['REQUEST_METHOD'].downcase
    when 'get'
      Net::HTTP.get(TWITTER.merge(env['REQUEST_URI']))
    when 'post'
      Net::HTTP.start(TWITTER.host) { |http| http.post(env['REQUEST_URI'], env['rack.input'].read) }
    end
  }
end

map '/env' do
  run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ env.map { |k,v| "#{k} : #{v}" }.join('<br>') ] ] }
end

map '/log' do
  run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ 'Thinking...' ] ] }
end

map '/test/' do
  run lambda { |env| Net::HTTP.start(TWITTER.host) { |h| [ h.code.to_i, h.each_header { |k,v| { k => v } }, [ h.body ] ] } }
end