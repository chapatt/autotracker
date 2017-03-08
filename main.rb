$simulate = true

unless $simulate
require 'rpi_gpio'
end # simulate

require_relative 'rotor.rb'
require_relative 'geo.rb'

Rotor.instance.units_angle = :deg
Rotor.instance.motor_steps = 400
Rotor.instance.motor_max_resolution = 16
Rotor.instance.min_rad = -2.25 * Math::PI
Rotor.instance.max_rad = 2.25 * Math::PI

Rotor.instance.to_relative_bearing(Geo.get_heading_to_station - Geo.get_current_heading)

unless $simulate
#RPi::GPIO.reset
end #simulate
