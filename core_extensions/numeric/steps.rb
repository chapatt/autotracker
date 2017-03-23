module CoreExtensions
  module Numeric
    module Steps
      def round_to_resolution(resolution)
        increment = Rational(1, resolution)
        return (self / increment).round * increment
      end
    end
  end
end
