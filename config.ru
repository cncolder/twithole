#\ -d -E development

require 'net/http'

class TwitHole
  def initialize(app)
    @app = app
  end
 
  def call(env)
    user_req = Rack::Request.new(env)
    method = user_req.request_method.downcase
    method[0..0] = method[0..0].upcase
    
    uri = URI('http://twitter.com').merge(user_req.fullpath)
    req = Net::HTTP.const_get(method).new(uri.to_s)
 
    if req.request_body_permitted? and user_req.body
      req.body_stream = user_req.body
      req.content_length = user_req.content_length
      req.content_type = user_req.content_type
    end
 
    req["X-Forwarded-For"] = (user_req["X-Forwarded-For"].to_s.split(/, +/) + [req['REMOTE_ADDR']]).join(", ")
    req["Accept-Encoding"] = user_req.accept_encoding
    req["Referer"] = user_req.referer
 
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
 
    headers = {}
    res.each_header do |k,v|
      headers[k] = v unless k.to_s =~ /cookie|content-length|transfer-encoding/i
    end
 
    [res.code.to_i, headers, [res.read_body]]
  end
end

use TwitHole

map '/' do
  run lambda { |env| [200, {"Content-Type" => "text/plain"}, ["Hello Twitter!"] ] }
end

map '/env' do
  run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ env.map { |k,v| "#{k} : #{v}" }.join('<br>') ] ] }
end

map '/test' do
  run proc { |env|
    req = Rack::Request.new(env)
    result = req.methods.map { |m| "#{m} : #{req.send(m) rescue nil}" }.join('<br>')
    [ 200, { 'Content-Type' => 'text/html' }, [ result ] ]
  }
end

# class TwitHole < Rack::Proxy
#   def initialize(app)
#     @app = app
#   end
#   
#   def rewrite_env(env)
#     env["HTTP_HOST"] = "twitter.com"
#     env
#   end
# 
#   def rewrite_response(triplet)
#     @triplet = triplet
#     status, headers, body = triplet
#     headers["X-Foo"] = "Bar"
#     triplet
#   end
# end

# run proc{|env| TwitHole.new(env).result }

# 
# map '/log' do
#   run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ 'Thinking...' ] ] }
# end