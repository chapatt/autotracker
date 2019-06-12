require 'nmea_plus'

class NMEAReceiver
  def initialize source_io
    source_decoder = NMEAPlus::SourceDecoder.new(nmea_source)
    source_decoder.each_complete_message do |message|
      unless message.all_checksums_ok? && message.all_messages_received?
        next
      end
  
      case message.data_type
      when "GPGGA"
        puts '% 2.5f % 2.5f' % [message.latitude, message.longitude]
        socket.send_string('Important', ZMQ::SNDMORE)
        socket.send_string('% 2.5f % 2.5f' % [message.latitude, message.longitude])
      when "GPVTG"
        puts '%2.0f heading at %0.1f knots' % [message.track_degrees_true, message.speed_knots]
      end
    end
  
    ObjectSpace.define_finalizer(self, proc {
      nmea_source.close
    });
  end
end
