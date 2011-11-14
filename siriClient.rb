#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'zlib'
require 'cfpropertylist'
require 'uuidtools'
require 'pp'

def plist_blob(string)
  string = [string].pack('H*')
  string.blob = true
  string
end

class SiriClient < EventMachine::Connection
  def connection_completed
    puts "Guzzoni TCP connection established. Setting up SSL layer"
    start_tls(:verify_peer => false)
  end

  def ssl_handshake_completed
    puts "SSL layer to Guzzoni established !"
    @zstream = Zlib::Deflate.new(Zlib::BEST_COMPRESSION)
    @ping = 1

    send_http_headers
    send_content_header

    send_ping

    @ping_timer = EventMachine::PeriodicTimer.new(1) do
      send_ping
    end

    send_object(
      { :class => 'LoadAssistant',
        :aceId => UUIDTools::UUID.random_create.to_s.upcase,
        :group => 'com.apple.ace.system',
        :properties =>
        { :speechId => 'COMMENTED_OUT',
          :assistantId => 'COMMENTED_OUT',
          :sessionValidationData => plist_blob("COMMENTED_OUT")
        }
      }
    )

    speech_session_ace_id = UUIDTools::UUID.random_create.to_s.upcase

    send_object(
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

    speech_packets = [
    ]

    index = 0
    File.open("input.sif", 'r').each_line do |packet|
      index += 1
      send_object(
        { :class => "SpeechPacket",
          :refId => speech_session_ace_id,
          :group => "com.apple.ace.speech",
          :aceId => UUIDTools::UUID.random_create.to_s.upcase,
          :properties =>
          { :packets =>
            [
              plist_blob(packet)
            ],
            :packetNumber => index
          }
        }
      )
    end

    send_object(
      { :class => "FinishSpeech",
        :refId => speech_session_ace_id,
        :group => "com.apple.ace.speech",
        :aceId => UUIDTools::UUID.random_create.to_s.upcase,
        :properties =>
        { :packetCount => speech_packets.length }
      }
    )

    flush_and_close_connection
  end

  def send_http_headers
    send_data ["ACE /ace HTTP/1.0", "Host: guzzoni.apple.com", "User-Agent: Assistant(iPhone/iPhone4,1; iPhone OS/5.0/9A334) Ace/1.0", "Content-Length: 2000000000", "X-Ace-Host: COMMENTED_OUT"].join("\r\n")
    send_data "\r\n\r\n"
  end

  def send_content_header
    #send_data "\r\n"
    send_data ["aaccee02"].pack('H*')
  end

  def send_object(object)
    plist = CFPropertyList::List.new
    plist.value = CFPropertyList.guess object
    plist_data = plist.to_str(CFPropertyList::List::FORMAT_BINARY)
    header = [(0x0200000000 + plist_data.length).to_s(16).rjust(10, '0')].pack('H*')

    send_data @zstream.deflate(header, Zlib::NO_FLUSH)
    send_data @zstream.deflate(plist_data, Zlib::SYNC_FLUSH)

    puts "Sent object"
  end

  def flush_and_close_connection
    #send_data @zstream.flush
    #@zstream.close
    # @ping_timer.cancel
    #self.close_connection_after_writing
  end

  def send_ping
    chunk = [(0x0300000000 + @ping).to_s(16).rjust(10, '0')].pack('H*')
    send_data @zstream.deflate(chunk, Zlib::SYNC_FLUSH)
    @ping +=1
    puts "Sent ping"
  end

  def receive_data data
    puts "Guzzoni received data #{data.length}"
    puts data
  end

  def unbind
    puts "Guzzoni connection closed !"
  end
end

EventMachine.run do
  EventMachine.connect('guzzoni.apple.com', 443, SiriClient)
  #EventMachine.connect('localhost', 443, SiriClient)
end
