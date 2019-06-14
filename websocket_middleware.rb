require 'thin'
require 'rack'
require 'faye/websocket'
Faye::WebSocket.load_adapter('thin')

require_relative 'web_positioner_frontend.rb'

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

      WebPositionerFrontend.instance.on_streaming_if_msg do |msg|
        ws.send(msg)
      end
  
      # Return async Rack response
      ws.rack_response
    else
      @app.call(env)
    end
  end
end
