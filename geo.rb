require 'geokit'

module Geo
  Geokit::default_units = :miles
  Geokit::default_formula = :sphere

  def self.get_current_heading
    # We're heading due east
    return 90
  end

  def self.get_bearing_to_station
    a = Geokit::LatLng.normalize(28.409465, -80.590945)
    b = Geokit::LatLng.normalize(28.381275, -80.548704)
    return b.heading_to(a)
  end
end
