#!/usr/bin/env ruby
require 'zlib'
Zlib::Inflate.inflate(File.open('in.dump.truncated').read)

# 63
# 65

# 0x63 = 0b 0110 0011
# 0x65 = 0b 0110 0101
#
# 0x78 = 0b 0111 1000
# CM = 1000 = 8, OK
# CINFO = 7 : 32k
# 0xDA = 0b 1101 1010
# FCHECK = 1010
# fdict = 1
# flevel = 11 = 3
