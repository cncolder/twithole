#############################################################################
#--
# Copyright (c) 2009-2010 Colder <cncolder@gmail.com>.
#   Released under the MIT license.
#++
#############################################################################

require 'net/http'

VERSION = '0.1.0'

TWITTER = 'http://twitter.com'

map '/' do
  run lambda { |env|
    case env['REQUEST_METHOD'].downcase
    when 'get'
      Net::HTTP.get(URI(TWITTER + env['REQUEST_URI']))
    when 'post'
      Net::HTTP.start(TWITTER) { |http| http.post(env['REQUEST_URI'], env['rack.input'].read) }
    end
  }
end

map '/env' do
  run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ env.map { |k,v| "#{k} : #{v}" }.join('<br>') ] ] }
end

map '/log' do
  run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ 'Thinking...' ] ] }
end