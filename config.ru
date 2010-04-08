# =====================================================
# = Twitter hole 0.1   Colder <cncolder.at.gmail.com> =
# =====================================================

require 'net/http'

class TwitHole
  # Twitter host address.
  TWITTER = URI('http://twitter.com').freeze
  
  # Twitter require these headers.
  HEADERS = [ 'Authorization', 'User-Agent', 'X-Twitter-Client', 'X-Twitter-Client-Version' ].freeze
  
  def initialize(app)
    @app = app
  end
 
  def call(env)
    user_request = Rack::Request.new(env)
    
    # Get user's browser http verb. eg. 'Get', 'Post'.
    request_method = user_request.request_method.capitalize
    
    # Build request full path.
    twitter_uri = TWITTER.merge(user_request.fullpath)
    
    # Use http verb to build http instance. But now u need get and post only.
    twitter_request = Net::HTTP.const_get(request_method).new(twitter_uri.to_s)
 
    # If it's post verb. Read post data.
    if twitter_request.request_body_permitted? and user_request.body
      twitter_request.body_stream = user_request.body
      twitter_request.content_length = user_request.content_length
      twitter_request.content_type = user_request.content_type
    end
    
    # Fetch user request. Filter out required headers.
    user_request.env.each do |k,v|
      key = k.gsub(/^HTTP_/, '').split('_').map { |s| s.capitalize }.join('-')
      twitter_request[key] = v if REQUIRED_HEADERS.include?(key)
    end
 
    # Send request then wait response from twitter.
    twitter_response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
    
    # Get twitter response headers. Maybe the best idea is filter it and make it simple.
    twitter_headers = {}
    twitter_response.each_header do |k,v|
      twitter_headers[k] = v
    end
    
    # If twitter return 3xx status code which means redirection. Change location to make u redirect to right address. Otherwise u will leave ur proxy site.
    twitter_headers['location'] = twitter_headers['location'].gsub(uri.host, user_request.host) if twitter_response.is_a?(Net::HTTPRedirection)
    
    # Log ur works. U can see this by type 'heroku logs' in ur shell.
    puts %{
  Started #{request_method} #{twitter_uri} for #{user_request['HTTP_X_REAL_IP']} at #{Time.now}
    Request #{req.each_header {}.map {|i| i.first + ':' + i.last.first}.join(' ')}
    Response #{headers.map {|k,v| k + ':' + v}.join(' ')}
    Finished #{twitter_response.code} #{twitter_response.msg}
    }
    
    # Return result to u.
    [ twitter_response.code.to_i, headers, [ twitter_response.read_body.gsub(uri.host, user_request.host) ] ]
  end
end

# Handle the root path can catch all request.
map '/' do
  # Use twit hole middleware.
  use TwitHole
  
  # This is a dummy line like u see. The middleware has do with all things. So this line will not work. But rack need it.
  run lambda { |env|
    [ 200, {"Content-Type" => "text/plain"}, [ "Hello Twitter!" ] ]
  }
end

# Visit this address u will see the server environments.
map '/admin/env' do
  run lambda { |env|
    res = env.map { |k,v| "#{k} : #{v}" }.join('<br>')
    [ 200, { 'Content-Type' => 'text/html' }, [ res ] ]
  }
end

# Visit this address u will see some info about ur request.
map '/admin/req' do
  run lambda { |env|
    req = Rack::Request.new(env)
    res = req.methods.map { |m| "#{m} : #{req.send(m) rescue nil}" }.join('<br>')
    [ 200, { 'Content-Type' => 'text/html' }, [ res ] ]
  }
end