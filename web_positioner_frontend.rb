require 'singleton'
require 'thin'
require 'rack'
require 'faye/websocket'
Faye::WebSocket.load_adapter('thin')

require_relative 'positioner_frontend_streaming_interface.rb'
require_relative 'positioner_frontend_rest_interface.rb'

class WebPositionerFrontend
  include Singleton

  def initialize
    @read_thread
    @queue_browse_mutex = Mutex.new

    @queues = {}
    PositionerFrontendRESTInterface::browse do |mq_change|
      case mq_change[:type]
      when :add
        @queue_browse_mutex.synchronize do
          @queues[mq_change[:id]] = mq_change[:mq]
        end
      when :remove
        @queues.delete mq_change[:id]
      end
    end
  end

  attr_reader :positioner

  def positioner=(positioner)
    if @positioner
      @positioner.closeSocket
    end
    @positioner = positioner
    if @positioner
      @positioner.openSubscriberSocket
      @positioner.send 'frontend-streaming-port'
      positioner_frontend_streaming_port = @positioner.receive

      @positioner_streaming_if = PositionerFrontendStreamingInterface.new @positioner.name, @positioner.address, positioner_frontend_streaming_port
      @positioner_streaming_if.openSubscriberSocket

      @sub_thread = Thread.new do
        while msg = @positioner_streaming_if.receive_with_type do
          puts msg
        end
      end
    end
  end

  def positioners_available
    @queues
  end
end

class WebSocketMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if Faye::WebSocket.websocket?(env)
      ws = Faye::WebSocket.new(env)
  
      ws.on :message do |event|
        ws.send(event.data)
      end
  
      ws.on :close do |event|
        p [:close, event.code, event.reason]
        ws = nil
      end
  
      # Return async Rack response
      ws.rack_response
    else
      @app.call(env)
    end
  end
end

class APIApp
  def call(env)
    req = Rack::Request.new(env)

    case req.path_info
    when "/positioners-available"
      mqs = WebPositionerFrontend.instance.positioners_available
      positioners = mqs.collect do
        |id, mq|
        { 'hash' => mq.hash, 'name' => mq.name, 'address' => mq.address, 'port' => mq.port }
      end
      [200, {'Content-Type' => 'text/json'}, [positioners.to_json]]
    when "/positioner"
      if req.get?
        if mq = WebPositionerFrontend.instance.positioner
          mq_json = { 'hash' => mq.hash, 'name' => mq.name, 'address' => mq.address, 'port' => mq.port }.to_json
        else
          mq_json = { }.to_json
	end
        [200, {'Content-Type' => 'text/json'}, [mq_json]]
      elsif req.put?
        mqs = WebPositionerFrontend.instance.positioners_available
        selected_hash = req.body.read.to_i
        selected_positioner = (arr = mqs.find do |id, mq|
          mq.hash == selected_hash
        end) ? arr[1] : nil
        WebPositionerFrontend.instance.positioner = selected_positioner
        [200, {'Content-Type' => 'text/json'}, [""]]
      end
    else
      [404, {'Content-Type' => 'text/json'}, [{ 'code' => 404, 'message' => 'Not Found' }.to_json]]
    end
  end
end
