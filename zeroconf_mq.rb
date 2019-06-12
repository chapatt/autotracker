require 'json'
require 'dnssd'

require_relative 'zmq_context.rb'
require_relative 'zmq_socket.rb'

class ZeroconfMQ
  DATA_SOURCE_VERSION = 1

  attr_accessor :name,
                :address,
                :txt_record,
		:dnssd_service,
                :socket

  def initialize name, address='*', port=nil, txt_record=nil, dnssd_service=nil
    self.name = name
    self.address = address
    self.port = port
    self.txt_record = txt_record
    self.dnssd_service = dnssd_service

    ObjectSpace.define_finalizer(self, proc {
      self.closeSocket
      self.stopDNSSDService
    })
  end

  attr_writer :port

  def port
    if @port.nil?
      @port = ZMQSocket.find_open_port (@address == '*' ? '0.0.0.0' : @address)
    end

    @port
  end

  def openSubscriberSocket
    @socket = ZMQContext.instance.open_socket self.class.subscriber_socket_type, self.address, self.port
  end

  def openProviderSocket
    @socket = ZMQContext.instance.open_socket self.class.provider_socket_type, self.address, self.port
  end

  def closeSocket
    @socket.close
  end

  def registerDNSSDService
    if self.respond_to?(:txt_record)
      txt = DNSSD::TextRecord.new(self.txt_record)
    else
      txt = nil
    end
    DNSSD::register(self.name, self.class.service_type, nil, self.port, txt) do |reply|
      self.dnssd_service = reply.service
    end
  end

  def stopDNSSDService
    @dnssd_service.stop if (@dnssd_service && @dnssd_service.started?)
  end

  def send_with_type data_type, data
    @socket.send_with_topic data_type, data
  end

  def send data
    @socket.send data
  end

  def receive_with_type
    @socket.receive_with_topic
  end

  def receive
    @socket.receive
  end

  def self.browse &block
    DNSSD::browse self.service_type do |reply|
      if reply.flags.add?
        DNSSD::resolve reply do |resolved_reply|
          addrinfo = DNSSD::Service.getaddrinfo(resolved_reply.target, DNSSD::Service::IPv4)[0]
          mq = self.new(resolved_reply.name,
                        addrinfo.address,
                        resolved_reply.port,
                        resolved_reply.text_record,
                        resolved_reply.service)
          block.call({ :type => :add, :id => reply.fullname, :mq => mq })
        end
      else
        block.call({ :type => :remove, :id => reply.fullname })
      end
    end
  end
end
