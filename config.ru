#############################################################################
#--
# Copyright (c) 2009-2010 Colder <cncolder@gmail.com>.
#   Released under the MIT license.
#++
#############################################################################

require 'net/http'

class Net::HTTP
  def begin_request_hacked(req)
    begin_transport req
    req.exec @socket, @curr_http_version, edit_path(req.path)
    begin
      res = Net::HTTPResponse.read_new(@socket)
    end while res.kind_of?(Net::HTTPContinue)
    res.begin_reading_body_hacked(@socket, req.response_body_permitted?)
    @req_hacked, @res_hacked = req, res
    @res_hacked
  end
  
  def end_request_hacked
    @res_hacked.end_reading_body_hacked
    end_transport @req_hacked, @res_hacked
    @res_hacked
  end
end
 
class Net::HTTPResponse
  def begin_reading_body_hacked(sock, reqmethodallowbody)
    @socket = sock
    @body_exist = reqmethodallowbody && self.class.body_permitted?
  end
  
  def end_reading_body_hacked
    self.body
    @socket = nil
  end
end

module Rack
  class HttpStreamingResponse
    def initialize(request, host, port = nil)
      @request, @host, @port = request, host, port
    end
    
    def status
      response.code.to_i
    end
    
    def headers
      h = Utils::HeaderHash.new
      
      response.each_header do |k, v|
        h[k] = v
      end
      
      h
    end
    
    def body
      self
    end

    def each(&block)
      response.read_body(&block)
    ensure
      session.end_request_hacked
    end
    
    def to_s
      @body ||= begin
        lines = []

        each do |line|
          lines << line
        end
        
        lines.join
      end
    end
    
  protected
    def response
      @response ||= session.begin_request_hacked(@request)
    end
    
    def session
      @session ||= Net::HTTP.start(@host, @port)
    end
  end
  
  class Proxy
    def call(env)
      rewrite_response(perform_request(rewrite_env(env)))
    end

    def rewrite_env(env)
      env
    end

    def rewrite_response(triplet)
      triplet
    end

  protected
    def perform_request(env)
      source_request = Rack::Request.new(env)

      target_request = Net::HTTP.const_get(source_request.request_method.capitalize).new(source_request.fullpath)
      target_request.initialize_http_header(extract_http_request_headers(source_request.env))

      if target_request.request_body_permitted? && source_request.body
        target_request.body_stream    = source_request.body
        target_request.content_length = source_request.content_length
        target_request.content_type   = source_request.content_type if source_request.content_type
      end

      target_response = HttpStreamingResponse.new(target_request, source_request.host, source_request.port)

      [target_response.status, target_response.headers, target_response.body]
    end

    def extract_http_request_headers(env)
      headers = env.reject do |k, v|
        !(/^HTTP_[A-Z_]+$/ === k)
      end.map do |k, v|
        [k.sub(/^HTTP_/, ""), v]
      end.inject(Utils::HeaderHash.new) do |hash, k_v|
        k, v = k_v
        hash[k] = v
        hash
      end

      x_forwarded_for = (headers["X-Forwarded-For"].to_s.split(/, +/) << env["REMOTE_ADDR"]).join(", ")

      headers.merge!("X-Forwarded-For" =>  x_forwarded_for)
    end
  end
end

class TwitHole < Rack::Proxy
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

map '/' do
  run lambda { |env| r = TwitHole.new; [ r.status, r.headers, r.body ] }
end

map '/env' do
  run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ env.map { |k,v| "#{k} : #{v}" }.join('<br>') ] ] }
end

map '/log' do
  run lambda { |env| [ 200, { 'Content-Type' => 'text/html' }, [ 'Thinking...' ] ] }
end