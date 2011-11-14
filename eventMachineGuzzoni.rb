#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'

Output = File.open('/tmp/out.dump', 'w')
Input = File.open('/tmp/in.dump', 'w')

class ProxyServer < EventMachine::Protocols::LineAndTextProtocol
  attr_accessor :guzzoni_connection

  def ssl_handshake_completed
    puts "SSL proxy layer established !"
    @data_to_send = ""
    self.guzzoni_connection = EventMachine.connect('guzzoni.apple.com', 443, Guzzoni)
    self.guzzoni_connection.proxy_server = self
  end

  def post_init
    puts "Server initialized"
    start_tls(:cert_chain_file => "./server.passless.crt",
              :private_key_file => "./server.passless.key",
              :verify_peer => false)
  end

  def receive_data(data)
    puts "Pipe length : #{@data_to_send.length}"
    Output.write data
    puts data
    puts "Receieved data from iPhone : #{data.length}"
    if guzzoni_connection.error?
      puts "Guzzoni connection not established"
      return
    end
    begin
      puts "Sending data to guzzoni"
      @data_to_send << data
      if guzzoni_connection.ssled
        guzzoni_connection.send_data(@data_to_send)
        @data_to_send = ""
      else
        puts "Couldn NOT forward, not SSLED"
      end
    rescue Exception => e
      puts "Error sending notification : #{e.inspect}"
    end
  end
end

class Guzzoni < EventMachine::Connection
  attr_accessor :proxy_server
  attr_accessor :ssled

  def connection_completed
    self.ssled = false
    puts "Guzzoni TCP connection established. Setting up SSL layer"
    start_tls(:verify_peer => false)
  end

  def receive_data data
    puts "Guzzoni received data #{data.length}"
    puts data
    Input.write(data)
    proxy_server.send_data(data)
  end

  def ssl_handshake_completed
    self.ssled = true
    puts "SSL layer to Guzzoni established !"
  end

  def unbind
    puts "ERROR !!!!! Guzzoni connection closed !"
    #EM.add_timer(5) do
      #self.reconnect('gateway.sandbox.push.apple.com', 2195)
    #end
  end
end

EventMachine.run do
  EventMachine::start_server '0.0.0.0', 443, ProxyServer
end
