require_relative 'zeroconf_mq.rb'

class PositionerFrontendRESTInterface < ZeroconfMQ
  POSITIONER_FRONTEND_PROTOCOL_VERSION = 1

  def txt_record
    { 'version'    => POSITIONER_FRONTEND_PROTOCOL_VERSION }
  end

  def self.service_type
    '_atprf._tcp'
  end

  def self.provider_socket_type
    :proxied_REP
  end

  def self.subscriber_socket_type
    :REQ
  end
end
