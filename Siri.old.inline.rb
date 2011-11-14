#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'zlib'
require 'cfpropertylist'
require 'uuidtools'
require 'pp'

class String
  def to_blob
    string = [self].pack('H*')
    string.blob = true
    string
  end

  def remove_leading_hex(hex_string)
    length = hex_string.length/2
    return self[length..-1] if self[0...length].unpack('H*').first == hex_string
    self
  end
end

module Siri
  class OutputStream
    def initialize
      @zstream = Zlib::Deflate.new(Zlib::BEST_COMPRESSION)
      @ping = 0
    end

    def content_header
      ["aaccee02"].pack('H*')
    end

    def object(object)
      plist = CFPropertyList::List.new
      plist.value = CFPropertyList.guess object
      plist_data = plist.to_str(CFPropertyList::List::FORMAT_BINARY)
      header = [(0x0200000000 + plist_data.length).to_s(16).rjust(10, '0')].pack('H*')

      @zstream.deflate(header, Zlib::NO_FLUSH) + @zstream.deflate(plist_data, Zlib::SYNC_FLUSH)
    end

    def ping
      @ping +=1
      chunk = [(0x0300000000 + @ping).to_s(16).rjust(10, '0')].pack('H*')
      @zstream.deflate(chunk, Zlib::SYNC_FLUSH)
    end
  end

  class InputStream
    def initialize
      @zstream = Zlib::Inflate.new
      @stream = ""
    end

    def <<(data)
      data = data.remove_leading_hex('0d0a') # Remove heading newline
      data = data.remove_leading_hex('aaccee02') # Remove ACE header
      @stream << @zstream.inflate(data)
    end

    def parse
      if @stream[0...5].unpack('H*').first.match(/040000..../) # Ignore 040000xxxx commands, those are PONGs
        puts "#####################################################"
        puts "* PONG : #{@stream[0...5].unpack('H*').first.match(/040000(....)/)[1].to_i(16)}"
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
        @stream = @stream[chunk_size+5..-1]
      end
    end
  end
end

class SiriClient < EventMachine::Connection
  def connection_completed
    puts "Guzzoni TCP connection established. Setting up SSL layer"
    start_tls(:verify_peer => false)
  end

  def ssl_handshake_completed
    puts "SSL layer to Guzzoni established !"
    @siriOutputStream = Siri::OutputStream.new
    @siriInputStream = Siri::InputStream.new

    send_data ["ACE /ace HTTP/1.0", "Host: guzzoni.apple.com", "User-Agent: Assistant(iPhone/iPhone4,1; iPhone OS/5.0/9A334) Ace/1.0", "Content-Length: 2000000000", "X-Ace-Host: COMMENTED_OUT"].join("\r\n") + "\r\n\r\n"
    puts "Sent HTTP headers"
    send_data @siriOutputStream.content_header
    puts "Sent content header !"
    send_data @siriOutputStream.ping

    @ping_timer = EventMachine::PeriodicTimer.new(1) do
      send_data @siriOutputStream.ping
    end

    send_data @siriOutputStream.object(
      { :class => 'LoadAssistant',
        :aceId => UUIDTools::UUID.random_create.to_s.upcase,
        :group => 'com.apple.ace.system',
        :properties =>
        { :speechId => 'COMMENTED_OUT',
          :assistantId => 'COMMENTED_OUT',
          :sessionValidationData => "COMMENTED_OUT".to_blob
        }
    }
    )

    speech_session_ace_id = UUIDTools::UUID.random_create.to_s.upcase

    send_data @siriOutputStream.object(
      { :class => "StartSpeechDictation",
        :aceId => speech_session_ace_id,
        :group => "com.apple.ace.speech",
        :properties =>
        { :keyboardType => "Default",
          :applicationName => "com.apple.mobilenotes",
          :applicationVersion => "1.0",
          :fieldLabel => "",
          :prefixText => "",
          :language => "fr-FR",
          :censorSpeech => false,
          :selectedText => "",
          :codec => "Speex_WB_Quality8",
          :audioSource => "BuiltInMic",
          :region => "fr_FR",
          :postfixText => "",
          :keyboardReturnKey => "Default",
          :interactionId => UUIDTools::UUID.random_create.to_s.upcase,
          :fieldId => "UIWebDocumentView0, NoteTextView1, NoteContentLayer0, NotesBackgroundView0, UIViewControllerWrapperView0, UINavigationTransitionView0, UILayoutContainerView0, UIWindow"
        }
    }
    )


    index = 0
    File.open("input.sif", 'r').each_line do |packet|
      send_data @siriOutputStream.object(
        { :class => "SpeechPacket",
          :refId => speech_session_ace_id,
          :group => "com.apple.ace.speech",
          :aceId => UUIDTools::UUID.random_create.to_s.upcase,
          :properties =>
          { :packets =>
            [
              packet.to_blob
            ],
              :packetNumber => index
          }
      }
      )
      puts "Sent speech packet"
      index += 1
    end

    send_data @siriOutputStream.object(
      { :class => "FinishSpeech",
        :refId => speech_session_ace_id,
        :group => "com.apple.ace.speech",
        :aceId => UUIDTools::UUID.random_create.to_s.upcase,
        :properties =>
        { :packetCount => index }
    }
    )

    #flush_and_close_connection
  end

  def flush_and_close_connection
    #send_data @zstream.flush
          #@zstream.close
    # @ping_timer.cancel
    #self.close_connection_after_writing
  end

  def receive_data data
    #puts "Received data from Guzzoni : #{data}"
    unless data.match(/Server/)
        @siriInputStream << data
        @siriInputStream.parse
    end
  end

  def unbind
    puts "Guzzoni connection closed !"
  end
end

EventMachine.run do
  EventMachine.connect('guzzoni.apple.com', 443, SiriClient)
  #EventMachine.connect('localhost', 443, SiriClient)
end
