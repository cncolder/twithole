#############################################################################
#--
# Copyright (c) 2009-2010 Colder <cncolder@gmail.com>.
#   Released under the MIT license.
#++
#############################################################################

require 'rack/proxy'

class TwitHole < Rack::Proxy
  def initialize(app)
    @app = app
  end
  
  def rewrite_env(env)
    env["HTTP_HOST"] = "twitter.com"
    env
  end

  def rewrite_response(triplet)
    status, headers, body = triplet
    headers["X-Foo"] = "Bar"
    triplet
  end
end

# use Rack::ShowExceptions
# use TwitHole

run proc{|env| [200, {"Content-Type" => "text/plain"}, ["Ha ha ha"]] }

# map '/env' do
#   run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ env.map { |k,v| "#{k} : #{v}" }.join('<br>') ] ] }
# end
# 
# map '/log' do
#   run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ 'Thinking...' ] ] }
# end