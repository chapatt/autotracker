require 'dnssd'
require 'json'

require_relative 'zmq_context.rb'
require_relative 'zmq_socket.rb'
require_relative 'positioner_frontend_streaming_interface.rb'
require_relative 'positioner_frontend_rest_interface.rb'
require_relative 'dc_rotor.rb'

class PositionerDriver
  def initialize
    @rotor = DCRotor.instance

    @streaming_if = PositionerFrontendStreamingInterface.new 'Rotor Streaming Interface'
    @streaming_if.openProviderSocket
    @streaming_if.registerDNSSDService

    @rest_if = PositionerFrontendRESTInterface.new 'Rotor REST Interface'
    @rest_if.openProviderSocket
    @rest_if.registerDNSSDService

    @pub_thread = Thread.new do
      while true do
        @streaming_if.send_with_type 'rel_bearing', @rotor.rel_bearing.to_s
        sleep 0.5
      end
    end

    @rep_thread = Thread.new do
      while (msg = JSON.parse(@rest_if.receive)) do
        case msg['resource']
        when 'frontend-streaming-port'
            if msg['method'] == 'GET'
                rep = { 'status' => 'success', :data => @streaming_if.port.to_s }.to_json
            end
        when 'rel-bearing'
            if msg['method'] == 'PUT'
                rep = { 'status' => 'success' }.to_json
                @rotor.to_rel_bearing msg['data'].to_i
            end
        end
        @rest_if.send rep
      end
    end
  end

  def update_data_sources
    new_sources = []
    DataSource.browse do |ds|
      new_sources << ds
    end
  end
end
