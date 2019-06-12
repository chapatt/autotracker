require_relative 'zeroconf_mq.rb'

class DataSourceNetworkInterface < ZeroconfMQ
  DATA_SOURCE_PROTOCOL_VERSION = 1

  attr_accessor :data_types

  def txt_record
    { 'version'    => DATA_SOURCE_PROTOCOL_VERSION,
      'data_types' => self.data_types.to_json }
  end

  def service_type
    '_atds._tcp'
  end

  def provider_socket_type
    :PUB
  end

  def subscriber_socket_type
    :SUB
  end
end
