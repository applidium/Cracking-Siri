#!/usr/bin/env ruby

require "socket"
require "openssl"
require "thread"

listeningPort = 443

server = TCPServer.new(listeningPort)
sslContext = OpenSSL::SSL::SSLContext.new
sslContext.key = OpenSSL::PKey::RSA.new(File.open("/Users/romain/server.key").read)
sslContext.cert = OpenSSL::X509::Certificate.new(File.open("/Users/romain/server.crt").read)
sslServer = OpenSSL::SSL::SSLServer.new(server, sslContext)

puts "Listening on port #{listeningPort}"

bufferSize = 16

loop do
  connection = sslServer.accept
  Thread.new do
    socket = TCPSocket.new('guzzoni.apple.com', 443)
    ssl = OpenSSL::SSL::SSLSocket.new(socket)
    ssl.sync_close = true
    ssl.connect

#    Thread.new do
#      begin
#        while lineIn = ssl.gets
#          lineIn = lineIn.chomp
#          $stdout.puts lineIn
#        end
#      rescue
#        $stderr.puts "Error in input loop: " + $!
#      end
#    end

 #   while (lineOut = $stdin.gets)
 #     lineOut = lineOut.chomp
 #     ssl.puts lineOut
 #   end


    begin
      while (buffer = connection.read(bufferSize))
        ssl.write buffer
        inBuffer = ssl.read

        lineIn = lineIn.chomp
        $stdout.puts "=> " + lineIn
        lineOut = "You said: " + lineIn
        $stdout.puts "<= " + lineOut
        connection.puts lineOut
      end
    rescue
      $stderr.puts $!
    end
  end
end

# ssl : proxy <-> Guzzoni
# connection : iPhone <-> proxy
#
# ssl.read -> récupère de guzzoni
# ssl.write -> envoie à guzzoni
# connection.read -> récupère de l'iPhone
# connection.write -> envoi à l'iPhone
