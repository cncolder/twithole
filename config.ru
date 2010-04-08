#\ -d -E development

require 'net/http'

class TwitHole
  def initialize(app)
    @app = app
  end
 
  def call(env)
    req = Rack::Request.new(env)
    method = req.request_method.downcase
    method[0..0] = method[0..0].upcase
 
    sub_request = Net::HTTP.const_get(method).new("#{uri.path}#{"?" if uri.query}#{uri.query}")
 
    if sub_request.request_body_permitted? and req.body
      sub_request.body_stream = req.body
      sub_request.content_length = req.content_length
      sub_request.content_type = req.content_type
    end
 
    sub_request["X-Forwarded-For"] = (req.env["X-Forwarded-For"].to_s.split(/, +/) + [req.env['REMOTE_ADDR']]).join(", ")
    sub_request["Accept-Encoding"] = req.accept_encoding
    sub_request["Referer"] = req.referer
 
    sub_response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(sub_request)
    end
 
    headers = {}
    sub_response.each_header do |k,v|
      headers[k] = v unless k.to_s =~ /cookie|content-length|transfer-encoding/i
    end
 
    [sub_response.code.to_i, headers, [sub_response.read_body]]
  end
end

use TwitHole
run Rack::Lobster.new

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

# map '/env' do
#   run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ env.map { |k,v| "#{k} : #{v}" }.join('<br>') ] ] }
# end
# 
# map '/log' do
#   run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ 'Thinking...' ] ] }
# end