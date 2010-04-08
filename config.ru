#\ -d -E development

require 'net/http'

class TwitHole
  def initialize(app)
    @app = app
  end
 
  def call(env)
    @req = Rack::Request.new(env)
    method = @req.request_method.downcase
    method[0..0] = method[0..0].upcase
    
    uri = URI('http://twitter.com').merge(@req.fullpath)
    req = Net::HTTP.const_get(method).new(uri.to_s)
 
    if req.request_body_permitted? and @req.body
      req.body_stream = @req.body
      req.content_length = @req.content_length
      req.content_type = @req.content_type
    end
    
    req['X-Forwarded-For'] = (@req['HTTP_X_FORWARDED_FOR'].to_s.split(/, +/) + [req['REMOTE_ADDR']]).uniq.join(", ")
    %w{Accept-Encoding Authorization Referer User-Agent X-Twitter-Client X-Twitter-Client-URL X-Twitter-Client-Version}.each { |h| req[h] = @req["HTTP_#{h.gsub('-', '_').upcase}"] }
 
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
    
    if res.is_a?(Net::HTTPRedirection)
      headers = {}
      res.each_header do |k,v|
        headers[k] = v
      end
      [ 200, {"Content-Type" => "text/html"}, [ headers.map { |k,v| "#{k} : #{v}" }.join('<br>') ] ]
    else
      headers = {}
      res.each_header do |k,v|
        headers[k] = v unless k.to_s =~ /cookie|content-length|transfer-encoding/i
      end
      [ res.code.to_i, headers, [ res.read_body.gsub(@req.host, uri.host) ] ]
    end
  end
end

map '/' do
  use TwitHole
  run lambda { |env|
    [ 200, {"Content-Type" => "text/plain"}, [ "Hello Twitter!" ] ]
  }
end

map '/admin/env' do
  run lambda { |env|
    res = env.map { |k,v| "#{k} : #{v}" }.join('<br>')
    [ 200, { 'Content-Type' => 'text/html' }, [ res ] ]
  }
end

map '/admin/req' do
  run lambda { |env|
    req = Rack::Request.new(env)
    res = req.methods.map { |m| "#{m} : #{req.send(m) rescue nil}" }.join('<br>')
    [ 200, { 'Content-Type' => 'text/html' }, [ res ] ]
  }
end