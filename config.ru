# =====================================================
# = Twitter hole 0.1   Colder <cncolder.at.gmail.com> =
# =====================================================

require 'net/http'

# Twitter host address.
TWITTER = URI('http://twitter.com')

# Twitter require these headers.
HEADERS = [ 'Authorization', 'User-Agent', 'X-Twitter-Client', 'X-Twitter-Client-Version' ]

class TwitHole
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
      twitter_request[key] = v if HEADERS.include?(key)
    end
 
    # Send request then wait response from twitter.
    twitter_response = Net::HTTP.start(twitter_uri.host, twitter_uri.port) do |http|
      http.request(twitter_request)
    end
    
    # Get twitter response headers. Maybe the best idea is filter it and make it simple.
    twitter_headers = {}
    twitter_response.each_header do |k,v|
      twitter_headers[k] = v
    end
    
    # If twitter return 3xx status code which means redirection. Change location to make u redirect to right address. Otherwise u will leave ur proxy site.
    twitter_headers['location'] = twitter_headers['location'].gsub(uri.host, user_request.host) if twitter_response.is_a?(Net::HTTPRedirection)
    
    # Log ur works. U can see this from '/admin/log' in ur browser.
    self.class.log.unshift({:time => Time.now.strftime('%Y-%m-%d %H:%M:%S'), :action => request_method.upcase.ljust(7) + twitter_uri.path, :result => twitter_response.msg}) if twitter_uri.path !~ /favicon\.ico$/
    
    # Return result to u.
    [ twitter_response.code.to_i, twitter_headers, [ twitter_response.read_body.gsub(twitter_uri.host, user_request.host) ] ]
  end
  
  def self.log
    @@log ||= []
    @@log.pop() if @@log.size > 1000
    @@log
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

# Visit this address u will see log about ur site.
map '/admin/log' do
  run lambda { |env|
    res = %{
<table bordercolor=#eeeeee cellspacing=20>
	#{TwitHole.log.map {|l| "<tr><td>#{l[:time]}</td><td>#{l[:action]}</td><td>#{l[:result]}</td></tr>"}}
</table>}
    [ 200, { 'Content-Type' => 'text/html' }, [ res ] ]
  }
end