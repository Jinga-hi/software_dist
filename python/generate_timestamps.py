#!/usr/bin/python

# v1.0 2014-08-29

# Reads a JAGA capture file and prints the data as a CSV, with a timestamp
# for each set of samples. The initial timestamp is determined as follows:
#
# (1) The first SKIP_COUNT packets are skipped because these often have
#     buffered latency effects.
#
# (2) The next CALC_COUNT packets are examined and the first sample time is
#     extrapolated based on the packet timestamp and the counters in the
#     packet data.
#
# (3) Due to packet jitter the extrapolated start times are not identical,
#     so we average them to remove jitter effects. LATENCY seconds are
#     subtracted to represent the packet latency on the network.
#
# (4) All the SKIP_COUNT and CALC_COUNT packets are then printed, using
#     the extrapolated and averaged start time, and with the in-packet
#     counters providing timing since start of capture.

import argparse
import packet
import sys

parser = argparse.ArgumentParser(
    description="Convert a capture file into a .csv")
parser.add_argument('--matlab', action='store_true')
parser.add_argument('filename')
args = parser.parse_args()
fh = open(args.filename, 'rb')

first_timestamp = None
first_seconds = None
first_sequence = None
last_timestamp = None
packet_buffer = []
packet_count = 0

SKIP_COUNT = 10  # Skip initial packets because their timing is odd.
CALC_COUNT = 100  # Use this many packets to find the first timestamp.
LATENCY = 0.003  # Latency of packet delivery on the network.

def get_packet(fh):
	try:
		p = packet.Packet(fh)
		return p
	except:
		return None

p = get_packet(fh)
uncorrected_time = p.timestamp - LATENCY
first_sequence = p.sample_count
first_seconds = p.seconds

while p and len(packet_buffer) < SKIP_COUNT:
	packet_buffer.append(p)
	packet_count += 1
	p = get_packet(fh)

first_timestamp_array = []
while p and len(first_timestamp_array) < CALC_COUNT:
	packet_buffer.append(p)
	packet_count += 1
	elapsed_time = p.get_elapsed_time(first_seconds, first_sequence)
	first_timestamp_array.append(p.timestamp - elapsed_time)
	p = get_packet(fh)

first_timestamp = sum(first_timestamp_array) / len(first_timestamp_array)
first_timestamp -= LATENCY


for pkt in packet_buffer:
	pkt.set_start_time(first_timestamp, first_seconds, first_sequence)
	if args.matlab:
		pkt.show_samples(epoch=True)
	else:
		pkt.show_samples()
packet_buffer = None

# There's a pending packet...
p.set_start_time(first_timestamp, first_seconds, first_sequence)

while p:
	packet_count += 1
	if args.matlab:
		p.show_samples(epoch=True)
	else:
		p.show_samples()
	try:
		# Call with full arguments.
		p = packet.Packet(fh, first_timestamp, first_seconds, first_sequence)
	except ValueError:
		p = None

fh.close()
sys.stderr.write("Number of packets read: " + str(packet_count) + "\n")
sys.stderr.write("Uncorrected start time: " + pkt.time2str(uncorrected_time) + "\n")
sys.stderr.write("Extrapolated start time: " + pkt.time2str(first_timestamp) + "\n")
