#\ -d -E development

require 'rack/proxy'

class TwitHole < Rack::Proxy
  def initialize(app)
    @app = app
    super()
  end
  
  def rewrite_env(env)
    env["HTTP_HOST"] = "twitter.com"
    env
  end

  def rewrite_response(triplet)
    @triplet = triplet
    status, headers, body = triplet
    headers["X-Foo"] = "Bar"
    triplet
  end
  
  def [](i)
    @triplet[i]
  end
end

# use Rack::ShowExceptions
app = TwitHole.new(env)

run app

# run proc{|env| TwitHole.new(env).result }

# map '/env' do
#   run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ env.map { |k,v| "#{k} : #{v}" }.join('<br>') ] ] }
# end
# 
# map '/log' do
#   run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ 'Thinking...' ] ] }
# end