require_relative 'zeroconf_mq.rb'

class PositionerFrontendStreamingInterface < ZeroconfMQ
  POSITIONER_FRONTEND_PROTOCOL_VERSION = 1

  def txt_record
    if @txt_record == nil
      { 'version' => POSITIONER_FRONTEND_PROTOCOL_VERSION }
    end
  end

  def self.service_type
    '_atpsf._tcp'
  end

  def self.provider_socket_type
    :PUB
  end

  def self.subscriber_socket_type
    :SUB
  end
end
