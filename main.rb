require 'eventmachine'
require 'websocket-eventmachine-server'
require 'json'

require_relative 'dc_rotor.rb'
rotor = DCRotor.instance

EM.run do
  WebSocket::EventMachine::Server.start(:host => "0.0.0.0", :port => 2345) do |ws|
    ws.onopen do
      puts "Client connected"
    end

    ws.onmessage do |msg, type|
      rotor.to_position msg.to_s.to_i
    end

    ws.onclose do
      puts "Client disconnected"
    end

    last = 0
    EM::PeriodicTimer.new 0.5 do
      if (last != (current = rotor.position))
        ws.send(current)
        last = current
      end
    end
  end
end
