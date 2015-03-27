#!/usr/bin/python

import sys
import struct

def read_uint16le(buffer):
  return struct.unpack('<H', buffer.read(2))[0]

def read_timestamp(buffer):
  return struct.unpack("<d", buffer.read(8))[0]

fh = open(sys.argv[1], 'rb')

samples_per_packet = {
    1 : 500,
    2 : 250,
    4 : 125,
    8 : 86,
    16: 43 }

ttl_reads = {
    1  : 32, 
    2  : 16, 
    4  : 8, 
    8  : 6, 
    16 : 3 
}

lastel = None
lastseq = None
total_lost = 0
total_received = 0
while True:
  try:
    timestamp = read_timestamp(fh)
    format = read_uint16le(fh)
    channels = read_uint16le(fh)
    bits_per_sample = read_uint16le(fh)
    sampling_rate = read_uint16le(fh)
    elapsed_seconds = read_uint16le(fh)
    sequence_number = read_uint16le(fh)
    #print elapsed_seconds,sequence_number
    total_received = total_received + 1
    if lastel is None:
      # First packet
      ttl = (bits_per_sample == 32784)  # Do we have TTL data?
    else:
      increment = sampling_rate * (elapsed_seconds - lastel)
      increment += sequence_number - lastseq
      lost_packets = (increment / samples_per_packet[channels]) - 1
      total_lost += lost_packets
    lastel = elapsed_seconds
    lastseq = sequence_number
    for i in range(samples_per_packet[channels]):
      for j in range(channels):
        read_uint16le(fh)
    if ttl:
      for i in range(ttl_reads[channels]):
        read_uint16le(fh)
  except struct.error:
    # End of file
    break
        
print "Sampling rate: ", sampling_rate
print "No. channels: ", channels
print "Packets received: ", total_received
print "Packets lost: ", total_lost
print "Total packets: ", total_received + total_lost + 1
print "Fraction lost: ", float(total_lost) / float(total_received + total_lost)
