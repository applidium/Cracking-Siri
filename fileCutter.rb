#!/usr/bin/env ruby
require 'zlib'


# Compression method and flags
# method : 8, the only one known
# flags : base-2 log of window size
#   in our case, we have 8192, so that would be 13, minus 8 = 5
#
# -> First byte = 0x85
# 
# Second byte. Let's say we don't want no dict
#
# bit 5 = 0
# bit 6 and 7 = 11 (max compression ?)
#
#

def generateZlibHeader(log_window_size, compression_level)
  cm = 8
  cinfo = log_window_size
  raise if log_window_size > 7

  cmf = (cinfo << 4) + cm

  fcheck = 0
  fdict = 0
  flevel = compression_level
  raise if compression_level > 4

  flg = 0
  (0..31).each do |potential_fcheck|
    fcheck = potential_fcheck
    flg = fcheck + (fdict << 5) + (flevel<<6)
    break if (cmf*256+flg).gcd(31) == 31
  end

  #puts "Using fcheck = #{fcheck}"
  #puts "CMF = #{cmf}, FLG = #{flg}"
#  puts "Header = #{cmf.to_s(16).upcase}#{flg.to_s(16).upcase}"
  return [cmf, flg].pack('cc')
end


file = File.open('in.dump').read.force_encoding('ASCII-8BIT')

(103..115).each do |position|
  #puts "POSITION = #{position}"
  #puts `dd if=in.dump bs=1 skip=2`
  #puts `dd if=in.dump bs=1 skip=#{position} 2>/dev/null | file -`
  #puts `dd if=in.dump bs=1 skip=#{position} 2>/dev/null | gunzip`
  #puts `dd if=in.dump bs=1 skip=#{position} 2>/dev/null`
  puts `dd if=in.dump bs=1 skip=#{position} 2>/dev/null | ./zpipe -d`
  (0..7).each do |log_win_size|
    (0..3).each do |comp_level|
      begin
        puts "#{position}x#{log_win_size}x#{comp_level}"
        truncated = generateZlibHeader(log_win_size, comp_level)
        truncated << file[position..-1]
        #deflated = Zlib::Inflate.inflate(truncated)
        File.open("test.bin", 'w') {|f| f.write(truncated)}
        deflated = `cat test.bin | ./zpipe -d`.force_encoding('ASCII-8BIT')
        puts deflated if deflated.match(/plist/)
      rescue Exception => e
        puts e
      end
    end
  end
end

# Summary : 020000018F or something similar is a "weird" marker between plist items
#
