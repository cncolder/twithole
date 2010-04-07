#############################################################################
#--
# Copyright (c) 2009-2010 Colder <cncolder@gmail.com>.
#   Released under the MIT license.
#++
#############################################################################

require 'net/http'

VERSION = '0.1.0'

TWITTER = '168.143.161.20'

class TwitterHole
  def initialize(env)
    headers = {}
    env.each { |k,v| headers[k] = v if k =~ /^HTTP_/ && k !~ /HEROKU/ && v }
    
    result = case env['REQUEST_METHOD'].downcase
    when 'get' then Net::HTTP.start(TWITTER) { |http| http.get(env['REQUEST_URI'], headers) }
    when 'post' then Net::HTTP.start(TWITTER) { |http| http.post(env['REQUEST_URI'], env['rack.input'].read, headers) }
    end
    
    [ result.code, result, result.body ]
    
  rescue => ex
    [ 500, { 'Content-Type' => 'text/html' }, [ [ex.class.name, ex.message, ex.backtrace].join('<br><br>') ] ]
  end
end

map '/' do
  run lambda { |env| TwitterHole.new(env).result }
end

map '/env' do
  run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ env.map { |k,v| "#{k} : #{v}" }.join('<br>') ] ] }
end

map '/log' do
  run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ 'Thinking...' ] ] }
end

map '/test' do
  run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ env.select { |k,v| k =~ /^HTTP_/ && k !~ /HEROKU/ && v }.inspect ] ] }
end