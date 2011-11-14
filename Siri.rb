#!/usr/bin/env ruby
require 'stringio'
require 'rubygems'
require 'eventmachine'
require 'zlib'
require 'cfpropertylist'
require 'uuidtools'
require 'pp'

class String
  def to_hex
    self.unpack('H*').first
  end

  def from_hex
    [self].pack('H*')
  end
end

module Siri
  class Client
  end

  class Server
  end

  class AceObject
    def self.has_header(header)
      @@headers ||= {}
      @@header = header.to_s[1..-1].to_i(16)
      @@headers[@@header] = self
      puts @@headers
    end

    def self.from_binary(stream)
      header = stream.readbyte
      puts "Instantiating item with header #{header}"
      obj_class = @@headers[header]
      obj_class.from_binary(stream)
    end

    def to_binary
      @@header.to_s(16).rjust(2, '0').from_hex + self.binary_payload
    end
  end

  class Notice < AceObject
    has_header :h03

    def initialize(index)
      @index = index
    end

    def self.from_binary(stream)
      self.new(stream.read(4).to_hex.to_i(16))
    end

    def binary_payload
      @index.to_s(16).rjust(8, '0').from_hex
    end
  end

  class Ping < Notice
    has_header :h03
  end

  class Pong < AceObject
    has_header :h04
  end

  class Payload < AceObject
    has_header :h02
    attr_accessor :object

    def initialize(object)
      self.object = object
    end

    def self.from_binary(stream)
      plist_data_length = stream.read(4).to_hex.to_i(16)
      puts "Chunk length = #{plist_data_length}"
      plist = CFPropertyList::List.new(:data => stream.read(plist_data_length))
      self.new(CFPropertyList.native_types(plist.value))
    end

    def binary_payload
      plist = CFPropertyList::List.new
      plist.value = CFPropertyList.guess(self.object)
      plist_data = plist.to_str(CFPropertyList::List::FORMAT_BINARY)

      plist_data.length.to_s(16).rjust(8, '0') + plist_data
    end
  end

  class SerializerStream
    def initialize
      @zstream = Zlib::Deflate.new(Zlib::BEST_COMPRESSION)
    end

    def <<(object)
      @zstream.deflate(object.to_binary, Zlib::NO_FLUSH)
      
      object.to_binary
    end

    def data
      # Returns the available data
    end
  end

  class DeserializerStream
    def initialize
      @inflate = Zlib::Inflate.new
      @stream = ""
    end

    def <<(data)
      @stream << @zstream.inflate(data)
    end

    def objects
      # Returns an array of parsed Siri objects
    end
  end
end

stream = StringIO.new(["020000FFFF"].pack('H*'))
puts Siri::AceObject.from_binary(stream)

