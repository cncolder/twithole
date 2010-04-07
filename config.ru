#############################################################################
#--
# Copyright (c) 2009-2010 Colder <cncolder@gmail.com>.
#   Released under the MIT license.
#++
#############################################################################

require 'net/http'

class TwitterHole
  VERSION = '0.1.0'
  
  # TWITTER = 'www.baidu.com'
  TWITTER = '168.143.161.20'
  
  REQUEST_HEADERS = %w[ ACCEPT
                        ACCEPT_LANGUAGE
                        ACCEPT_ENCODING
                        ACCEPT_CHARSET
                        CACHE_CONTROL
                        CONTENT_LENGTH
                        CONTENT_TYPE
                        CONNECTION
                        COOKIE
                        HOST
                        IF_NONE_MATCH
                        KEEP_ALIVE
                        PROXY_CONNECTION
                        REFERER
                        USER_AGENT ].freeze
  
  def initialize(env)
    @env = env
  end
  
  def env
    @env
  end
  
  def method
    env['REQUEST_METHOD'].downcase
  end
  
  def uri
    env['REQUEST_URI']
  end
  
  def data
    env['rack.input'].read
  end
  
  def headers
    # Hash[ @env.select { |k,v| REQUEST_HEADERS.include?(k.gsub(/^HTTP_/, '')) }.map { |pair| [ pair.first.gsub(/^HTTP_/, ''), pair.last ] } ]
    Hash[ env.select { |k,v| k =~ /^HTTP_/ && k !~ /HEROKU/ }.select { |a| a.size == 2 } ]
  end

  def get
    Net::HTTP.start(TWITTER) { |http| http.get(uri, headers) }
  end
  
  def post
    Net::HTTP.start(TWITTER) { |http| http.post(uri, data, headers) }
  end
  
  def result
    result = send(method)
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
  run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ Hash[ env.select { |k,v| k =~ /^HTTP_/ && k !~ /HEROKU/ && v } ].inspect ] ] }
end