$simulate = true

unless $simulate
require 'rpi_gpio'
end # unless $simulate

require 'eventmachine'
require 'websocket-eventmachine-server'

require_relative 'rotor.rb'
require_relative 'simulator.rb'
require_relative 'geo.rb'

require_relative 'core_extensions/numeric/angle.rb'
Numeric.include CoreExtensions::Numeric::Angle

t1 = Thread.new do
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

      last = 0
      EM::PeriodicTimer.new 0.5 do
        if (last != (current = Simulator.instance.position.convert(Rotor.instance.motor_steps, 2 * Math::PI).to_f))
          ws.send current
          last = current
        end
      end
    end
  end
end

t2 = Thread.new do
  EM.run do
    EM::PeriodicTimer.new Rotor.instance.step_pause do
      if Rotor.instance.step_queue != 0
        Rotor.instance.next_in_queue
      end
    end

    EM::PeriodicTimer.new 5 do
      Rotor.instance.to_relative_bearing(Geo::get_heading_to_station - Geo::get_current_heading)
      puts "intended heading: #{Geo::get_heading_to_station - Geo::get_current_heading}"
      puts "step queue #{Rotor.instance.step_queue}"
      puts "current position: #{Rotor.instance.position}"
    end

    EM::PeriodicTimer.new 5 do
      if Rotor.instance.error.nil?
        puts "Error!"
        EM.stop_event_loop
      end
    end
  end
end

t1.join
t2.join

unless $simulate
#RPi::GPIO.reset
end # unless $simulate
