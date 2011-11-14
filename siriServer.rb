#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'zlib'
require 'cfpropertylist'
require 'pp'

class String
  def remove_leading_hex(hex_string)
    length = hex_string.length/2
    return self[length..-1] if self[0...length].unpack('H*').first == hex_string
    self
  end
end

module SiriServer
  include EventMachine::Protocols::LineText2
  def ssl_handshake_completed
    puts "SSL proxy layer established !"
    @zstream = Zlib::Inflate.new
    @stream = ""
  end

  def post_init
    start_tls(:cert_chain_file => "./server.passless.crt",
              :private_key_file => "./server.passless.key",
              :verify_peer => false)
  end

  def receive_binary_data(data)
    #puts data.bytes.to_a.map{|i| i.to_s(16).rjust(2, '0')}.join(" ")
    data = data.remove_leading_hex('0d0a') # Remove heading newline
    data = data.remove_leading_hex('aaccee02') # Remove ACE header
    @stream << @zstream.inflate(data)
    parse
  end

  def unbind
    #@zstream.finish
    @zstream.close
  end

  def receive_line(line)
    puts line
    set_binary_mode if line.match(/X-Ace-Host/)
  end

  def parse

    if @stream[0...5].unpack('H*').first.match(/030000..../) # Ignore 030000xxxx commands
      puts "#####################################################"
      puts "* PING ? : #{@stream[0...5].unpack('H*').first.match(/030000(....)/)[1].to_i(16)}"
      @stream = @stream[5..-1]
    end

    chunk_size = @stream[0...5].unpack('H*').first.match(/0200(......)/)[1].to_i(16) rescue 1000000
    if (chunk_size < @stream.length+5)
      plist_data = @stream[5...5+chunk_size]
      plist = CFPropertyList::List.new(:data => plist_data)
      puts "#####################################################"
      plist_object = CFPropertyList.native_types(plist.value)
      pp plist_object
      (plist_object["properties"]["packets"] || []).each do |packet|
        puts packet.length
        File.open("data.spx", "a"){|f| f.write(packet)}
      end
      #self.send_data "Received an audio chunk !"
      @stream = @stream[chunk_size+5..-1]
    end
  end
end

EventMachine.run do
  EventMachine::start_server '0.0.0.0', 443, SiriServer
end
