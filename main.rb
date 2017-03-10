$simulate = true

unless $simulate
require 'rpi_gpio'
end # simulate

require 'eventmachine'
require 'websocket-eventmachine-server'

require_relative 'rotor.rb'
require_relative 'simulator.rb'
require_relative 'geo.rb'

Rotor.instance.step_pause = 0.1
Rotor.instance.motor_steps = 400
Rotor.instance.motor_max_resolution = 16
Rotor.instance.min_rad = -2.25 * Math::PI
Rotor.instance.max_rad = 2.25 * Math::PI

EM.run do
  WebSocket::EventMachine::Server.start(:host => "0.0.0.0", :port => 2345) do |ws|
    ws.onopen do
      puts "Client connected"
    end

    ws.onmessage do |msg, type|
      puts "Received message: #{msg}"
    end

    ws.onclose do
      puts "Client disconnected"
    end

    EM::PeriodicTimer.new 0.5 {ws.send ((Simulator.instance.position % 400) / 400 * 360).to_f}
  end

  EM::PeriodicTimer.new 0.5 do
    if Rotor.instance.step_queue != 0
      Rotor.instance.next_in_queue
    end
  end

  EM::PeriodicTimer.new 5 do
    Rotor.instance.to_relative_bearing(Geo.get_heading_to_station - Geo.get_current_heading)
  end
end

unless $simulate
#RPi::GPIO.reset
end #simulate
