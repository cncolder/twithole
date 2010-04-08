#\ -d -E development

require 'net/http'

class TwitHole
  def initialize(app)
    @app = app
  end
 
  def call(env)
    @req = Rack::Request.new(env)
    method = @req.request_method.capitalize
    
    uri = URI('http://twitter.com').merge(@req.fullpath)
    req = Net::HTTP.const_get(method).new(uri.to_s)
 
    if req.request_body_permitted? and @req.body
      req.body_stream = @req.body
      req.content_length = @req.content_length
      req.content_type = @req.content_type
    end
    
    req['X-Forwarded-For'] = (@req['HTTP_X_FORWARDED_FOR'].to_s.split(/, +/) + [@req['REMOTE_ADDR']]).uniq.join(", ")
    @req.env.each do |k,v| 
      if k =~ /^HTTP_/ and k !~ /HEROKU/
        key = k.gsub(/^HTTP_/, '').split('_').map { |s| s.capitalize }.join('-')
        req[key] = v
      end
    end
 
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
    
    headers = res.each_header
    res.each_header do |k,v|
      headers[k] = v # unless k.to_s =~ /cookie|content-length|transfer-encoding/i
    end  
    headers['location'] = headers['location'].gsub(uri.host, @req.host) if headers['location']
    
    puts %{
Started #{method} #{uri} for #{@req['REMOTE_ADDR']} at #{Time.now}
  Request #{req.each_header {|k,v| p k}}
  Response #{headers.map {|k,v| k + ':' + v}.join(' ')}
  Finished #{res.code} #{res.msg}
    }
    
    [ res.code.to_i, headers, [ res.read_body.gsub(uri.host, @req.host) ] ]
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