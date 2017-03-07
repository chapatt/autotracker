require 'geokit'

module Heading
  Geokit::default_units = :miles
  Geokit::default_formula = :sphere

  a = Geokit::LatLng.normalize(28.409465, -80.590945)
  b = Geokit::LatLng.normalize(28.381275, -80.548704)
  puts b.heading_to(a)
end
