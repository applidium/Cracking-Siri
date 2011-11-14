#!/usr/bin/env ruby
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'cfpropertylist'
require 'zlib'

require 'pp'

pkey = cert = cert_name = nil

begin
  pkey = OpenSSL::PKey::RSA.new(File.open("server.key").read)
  cert = OpenSSL::X509::Certificate.new(File.open("server.crt").read)
end

class Simple < WEBrick::HTTPServlet::AbstractServlet
  
  def do_ACE(request, response)
    puts "ACE request !"
    puts request.body
    pp request
    puts "Coule"
    #status, content_type, body = do_stuff_with(request)
    
    #response.status = status
    #response['Content-Type'] = content_type
    response.body = "Blah"
  end
end

server = WEBrick::HTTPServer.new(
  :Port => 443,
  :Logger => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
  :DocumentRoot => "/ruby/htdocs",
  :SSLEnable => true,
  :SSLVerifyClient => OpenSSL::SSL::VERIFY_NONE,
  :SSLCertificate => cert,
  :SSLPrivateKey => pkey
  #:SSLCertName => [ [ "CN",WEBrick::Utils::getservername ] ]
)

server.mount "/ace", Simple


server.start
