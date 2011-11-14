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
      "37748e774c000068e8e8e8e8e8e8e88401f474745e7ffc3c4013d1945623c83137b1b247eebbf8d6c8b8c8d885db3b64ababababab1ab74958d6d0cd4d8dc26b0cdd956f34931d6533bec50cdd74ea985b116c43ba5aea8bdeeead9a7a0835d9f66d2eb8e87d2c7a0c70cf8883618883710f4db93f0c5edd6018e0c3d571a79f0d68d9356783abababc22835f20b0e68a7f3fb7baea6468900c1ff9da1baaf466eb28d009880d8823d27b3f33c6a69cfdbc1718e9c2ab3ef1bbb62f30dababab16b6da7c7d6249434972003b4ebb10b4235ff09a2add756596e2b98c88201dc3433c19e5917306f646d097e484d4cdb0d77bcb431e2b61f108b49496baf5be6828e27c98e741b680b4b1ab21934abebc730d4fb7d64235f8fba2addeb7b5bfdf7ee14cc08500231f5c5319a43060d622828ef64805566f601e25764f4d18a983bf18243bc5f3abadb8d6c9347d5d98a8b3324a0234fd4d6d9ccfec337217ac74b1f0b4167d3791c36466f5a0f825bb4e7cbaedb955043da67923800fb3c44d7afdb2423db7d66575b0be7e5f8dac0bbc02d4b156978829b391e725a13e29c98e9f35f063636b4e672eb4d689665d6ac4eb7b3cddc210cb8ae450d5c7cb72fa089167ee07a6cfed571105d535c8400bb8716512818e784d6c83d6d402bc3c62394920ced10206d356aec13ed608510c641716d9806f1e2273cdc73911670ae904afc5cd940c05538399cdf7e79a5ede916103017dbf9f32c98b8b1aa0edc03bc04906df83956ab049abab427330510827ef53f295beb20940c616cdefe762de76b08b68977cc9fcd691b0548f39a042129ee39f3020ba2e97082be5804249bd0d4200abdc2428000dc2bdc9490d6428d6b49357e9c116eb17fdfc606c15ea021d4d53db0febcc67310b3286a87b08b4f31acae2999b5c3cf2a10d51c901fdc6be580abab2749140ababab426b00e5649abab08e8d42c93d",
      "357dac112dadc332f241595a317334d6bf31a3cc439c755e6591c7cf3ad19b5a0c2622a8effb2da82c629fd219cbc580c28abd271c089bdbde5db0ad80566b8b044c34de7ab35ec630e6f492bdbbbf82b98995588a48fe9732439a4b6dad45257d3b4223736d06c5cc91774243eb301957b4d1bf840d632495827438c9abbc7505afed6ab2006b812dac5535f3350e6f4a82ad05447c9b6d514f239d40835dee5c009d0a52316452e2ee10a39d624938610b9340a8c4da55dbf8e0c990a773120fe3b141f9c09cef5e3d930e75678d9693562ef4590497fc1665a3638ed34892671837e9333428d1a6693b1d7038593528046d169dfed777321a2a7e4ddabba700d532d495d075ed9ca09d0fe2df80dbc1b4340a39e3373842be8f4fdf492e66f4e62eea0728efe5597354953586a25407ff3ba439cb828c2caa97f9214786712d7f0b2bba703e930156560d694420df30846beb0e4d0f38d84bdcd376e49146e570f43336bd208192a2eceabb8e81246466ebabf53d1b4d0a4c4336dea9e931ed8ccd578ad24cdc96bb9f0fa493abc0e0f8d630f8550b17e12029c06d490d8e1031283e52d14bc1eac531169cae31784e33fc34646ca0cc745d736dcd59ddfecc00663af37e3587321d8ba8991bab2af038d6d90e0004249abab3c084abbdab0e0b775f3c2f8377fc0734edee2933b018639fd4485acaf513902632532768255d18428d1815cbecff44a43c6800e1e20d8b34d2b38f0548e8d42c90844d840e49040ebbd0d6305f80ad06cd3774a6bd52551d218505d8e141f5c69b9b869b3f340675fd389566e607e63a4a8e3d7c1a9f64ae00ae1f3f594bab41f00e0d3ded0e0ab0e94c9b80b88d8d789200d6d6d948e357aede2522bfb87063cb3b169077fb3bf19ed4ff12bc3bff5999c8dca8a338df00ef72d3fca6decb5f6ee8163fbf9f0f339275ebb04a7af3ab07079206dc7ac0a91b5ac7bd",
      "356ecfe37068df821f9b087226f7f8b58fa21d11aa26a91f8d1a1ef23cba8f5a260bee2d6be0d945067716e4bd8bf9f0140e7f8e8a0a463b282270f38a630dc20cdfed949e5357aa1e4916ae2cf384ad81faf2f867d4f81b00ec93cc446741c05b95d8dbe2dc4eb46ee17e039132d1c6d6b9e3b38f06c01d27a73020a000d402069010a59bd084ad6d9fa037761cbaf172beb19e5937695f44683aa3733fe4a94fd46ff5dcdf907a322eaa3d1961ade3fdb1b14d25c20bfd0bbac020a980ad9d0c8a765de033ab8e3294bd09cb28171a7377dc8b9516d7f077812b74f6ae4f46cf17b3be37d3ceb2fb75007c3f4bb8a414e212a9ee8e286e102d83901662bfad180cf1b26c407a62b0c94908e0e3dba670c5eb598e0e3572cf310e31fa491b60985ecf17a8cffde5d5da2dddb51b83b4d5bde10e972c4b5fcd7ce8e6e13b3ee7e29c50fbfbc0a008adf11e294dcfb7a622e10aab73380abab0acdd635dbac2ef2a999e1f068e9799daf33bae2d5135ba0b4fc2bf003dd487b90fe9a55243f1db6fd1eb4c8990118565b5d80bd42d6615d0ef80bda7040808d4000231ed923d46b931c2e1d2f12bfb736b4708e05f558cf6aefab1a6905a6d338855f6c2ac394b0d2c57560acdce97fee97f80eba27b8c8043121245d91a70bd309d00a16e4eb0561d574d310af33839ceeb0630aa58cbccd6a7a36d3ceab8605ae26f8c4058f7897c9958a01c250506c7c2beeb63329b882587a2b4581ba69d88b100597b8b07391e3d9da28700ea803083c831c648cb50d56f79ad3bca43f8f09b6cbf70d6210e1e3732a69838e9c76db4374e1232313460db72d5ef7d8d2f9b8d81e52f65c3d415739fe17350503b44a94217a00d9498c37767d645068c6d2ae545cf5b17a12b8cdda7cfc41d69b3c695c5ece79a2820a2d6d6c6e63fd2f93169b2b5f7e6b61f0c389cdd6ab0bccdededcd04deb04bdc90c2c93d3d3d",
      "377648bab0735f91e8f91dad2fe98a39afeb8217afcda5bf9d1d72cc172706588a6f3deefc787f0f2d09a6d78bfbde50c2ababc2780b83d94753808e56ab0d400edab0d149c377691654f741f8bd9ff685b66b7aab95fcf038b89389d8b170933db981c6a799e2f9e4de8f04cc31f5efa062f5b3e50002d0f91ac0930862939022d1272754d1b78b01e56b3383edfcf01ef66588b1af69564cceb0374fad28f410fda416bf1dfb4a229b621882f9751c673ee578babd084f0b3df327129d32e4478d280dece3593cceb4d34ba92a0f8d432869dabd1281ee32f3d35842c9eaa2cd993860e2883b6d32e8b63d81b5a520d82176d97fd6fac99a178c62f884be55314d4844a14200f39d9e7e49ede786bea2af18a05d3136842b93f1746ea95fdc51536d43e4829fb9402417fca8c1280ac2b6e677e31dbb55ba8bccebe6ef24929173ecab9f837448d481432e82d3cce2d168c0249c4d05c1c3856d9368412d150b58f050f002596e628329e5b7ff993d4ef428b6a920ea801dfa33644f95669d6dce568377ee6eb982be6d053777a97550a956145a6d0ebbebdcdcd0948d276d5633d62962ae430f2e3d937b635abc06ba85a16ad7332274f5b8cd70c718a349459736984ed0c414cb1ca210c5fdbbfbf09c409c4249025be7a9c0a0f36dcd9b2d0af9e471a3433eac715909285c335b1dedfc5636d0243bc765fc87141af7f4fc7db52834885207c5e8d16ded3a69f3435cd75fbfbf1fa84da9f5d0c9d6cdd62708e27dad2100ef6db8d6cf372e30835062bf4e09225a7d28f9e9c57b3e7f86dd351723705b2ec9326367cb1223304dde6f9b5bdec9a3742f9be650d46787590e0db7efaf1140e21381404905e9e1bcebb372e248c506f6f245d2b601af2fc50bc63b1428f345698cc74de07c0a51b96092bf1dc8f087e32f6aaa1f1688d0be6f12dd4d24d0a256c0384d371017ead1c5d05e2794b8d4",
      "372e688f51a2b68e27c21ddc24c9eebd63a83ab21af498864e9eb8a69cfc63368f85e6cfabe5a6e32d265523b71be450b10b6d1c04049c9f856d905201c0d21408ebd8d6d31372903f7507ce358c04a45452baa693e918179545bbfa3c527df37b335580dc00a40f90fafd3aec91f0cb661cf1bbbc0aa3256499c0aba7560d8e06d8000bd0a038498dab423577ee452e267f56c960efa077883bba3fb8bd4dc686b3873b1e0fae3b9608d37273a02e476b302f3a4c59609d3bbbf0a78d30e27301cb86ddecd0ad5ac7cede0ab5934fac937716e72ac726fa5d24a014670b56636bfed37348b8435aace5f1fc259a3536bad9181adff52ca6916962dae98abbbf0b14f5f0dbd00a00ed015405e12ad207e21b0d000334373330934ba6f74177e2ed2bceb09805d1b49e3552e9b1bb7d0770c64a496b59ac6d205878d7c2c8500d92b00f4bbbf120b97af399157791fd6bb11467d878df20a548a65fe372c24910ab97f3d410e7a4f9cfbb0b70feaf45b7afc84669bde97d31f18ae0a47f9f92e28d82ff27d49001bd61bbbf28054a4fc4d56b0e94f88f2b990548e4939d849e9f9c30d33e3f687e1f1adeff5116d944f63ee1fcfadb1942b391db95fcf4cfbfbc433083cfeb6ae50f35f1940540ab8be7f51c3d149b5d5cef73ad6424b7b342347a8145b02495a35dcedbc8f87cfb5b2274cfcaf6b7b82fc814a7f73a81a31bdff7c38fc0b644b6dfb1e59c8adcac3f9a990d1134bbbf3f6a74fc2ab34400a70ac24ca14be8e5a49b89867a5637610e774bc356281f448575e6f0af119b6f8110fb2029cb1b8029a9ec24d9e2bf4fe93a3e6ef8a91686b891d50bbbf5698e0c59c03ade7b0c5e54a70081521c20d40adb04e376b77124d15362c9e4f086f628eefbb9b704b8de8b4b5ca7f57fcd8acc8c5972a744e8946c3a1686785c11ca8abb9c1c26b49a0390a701bd92e500affad9ced00e59889f54",
      "31db0639eac47fc5f9fa760b3ab93ae537ebdddc4cc63b3473b0fec048c2eb9a36e91a741ee9b9f113d830b0574bbb4094ed6273840bd56143d130a0008055890bdd6420e5631caec168a13d362bd2bdf6216eb7075bfa1731949e277fd9d310eb738daa252028b38d796db40fc1f9c81172c8bb8703dfe42ad940e7d2a756420c9978eeb490c9aba71442329c22a54a93f3adff55f6455178e25f37936666ba47f000b2ab41d5b59d6bfccd0294140eebe4870b279dcc637be6500eeb6ddeed00e42edebc00812d4d08ed042adf80dad329700a1aa3a0b41d4151230aaef03c5ab4389925d25f3ab5b5f01a8063a4ae52956e1b6a6d3962b16f4c538a02be7f0f152781c9b0e89e3094eb1c9830983c21eb788e9852339b6e10aad3932f46e9084dffcc968ff5bcc460a66fe00dc0294dc1b15d9e99cc0593e90dd007a71bbdf0a5a77bbfc042802930b8013808e8e6d1fbc86d6df7209af2dd32d329900a6a9ef874a106b9889b0406dd043973798baafe7815268c1d35bc5701ad59aa4fe66dea1000b021dcdec9be4f21c842db0db480271d5fc2292345d344a32e396b710031c8b30d48be669ba1bbafea429804c75b708a0db7a7579b7d3e559fef4731fc704083240ece2093e4bf704374bbbbf4471090f1712e9ac1c93ba275927a926d2462d62083b31da6d77894d9a4efbaddbe0f261e126ed40de1a90100f7a418f76c0de8981605bfd20c048e1dda0e62a41e5111b3bf12d310201730000e2deb1c049ebab3d2708e568480b131c8f30a275687af34091a5bca2e185023a26fab768ff50f824641d5c9628aa64633a5b316d28c012ab77303794b3870f3106b31e50bbbb762d9b0348da7000a1d98ac9edfa31caa90b08f6b6635f0e66d2f9e6ddd3f9ad0103a399bb26f46819b1c367f6096b0a2873be5808df1728a2d5490b3bf000123297c40fad41f52bd0207e499c040cd2d0d62c3"
    ]

    speech_packets.each_with_index do |packet, index|
      sleep 0.5
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
