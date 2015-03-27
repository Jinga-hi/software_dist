import struct
import time
from struct_methods import *

class Packet:
	'''Read a single JAGA packet given an input buffer'''
	SAMPLES_PER_PACKET = {
		1 : 500,
		2 : 250,
		4 : 125,
		8 : 86,
		16: 43 }

	def __init__(self, buffer, start_time=None, first_seconds=None, first_sequence=None):
		self.all_samples = []
		try:
			(self.timestamp, self.channels, self.bits_per_sample,
			 self.samples_per_second, self.seconds,
			 self.sample_count, self.ttl) = self.data_header(buffer)
        		self.packet_assembly_time = (
			    float(self.SAMPLES_PER_PACKET[self.channels])
			    / (float(self.samples_per_second)))  # in sec
			self.data_samples(buffer)
		except struct.error:
			# Out of data, exit cleanly.
			raise ValueError
		self.start_time = start_time
		self.first_seconds = first_seconds
		self.first_sequence = first_sequence

	def data_header(self, buffer):
		'''Read the data header and return header values'''
		timestamp = read_doublele(buffer)
		version = read_uint16le(buffer)
		channels = read_uint16le(buffer)
		bits_per_sample = read_uint16le(buffer)
		samples_per_second = read_uint16le(buffer)
		seconds = read_uint16le(buffer)
		sample_count = read_uint16le(buffer)
		if bits_per_sample == 16 + 32768:
			ttl = True
		else:
			ttl = False
		return (timestamp, channels, bits_per_sample,
		   samples_per_second, seconds, sample_count, ttl)

	def set_start_time(self, start_time, first_seconds, first_sequence):
		'''Set the actual start time and counters if known'''
		self.start_time = start_time
		self.first_seconds = first_seconds
		self.first_sequence = first_sequence

	def data_samples(self, buffer):
		'''Read all the data samples from the packet'''
		this_packet_samples = 0
		for i in range(self.SAMPLES_PER_PACKET[self.channels]):
			fraction = (float(this_packet_samples) *
			    float(self.packet_assembly_time)
			    / float(self.SAMPLES_PER_PACKET[self.channels]))
			samples = []
			for j in range(self.channels):
				sample = str(read_uint16le(buffer))
				samples.append(sample)
				this_packet_samples = this_packet_samples + 1
			self.all_samples.append(samples)

	def show_samples(self, epoch=False):
		'''Display data samples from the packet. start_time must be known.'''
		assert(self.start_time is not None)
		assert(self.first_seconds is not None)
		assert(self.first_sequence is not None)
		sample_string = ''
		elapsed_time = self.get_elapsed_time(self.first_seconds, self.first_sequence)
		for i in range(len(self.all_samples)):
			fraction = float(i) * float(self.packet_assembly_time) / float(self.SAMPLES_PER_PACKET[self.channels])
			current_time = self.start_time + elapsed_time + fraction
			if epoch:
				# Just output as floating point.
				timestr = "{:06f}".format(current_time)
			else:
				timestr = self.time2str(current_time)
			sample_string = timestr + "," + ",".join(self.all_samples[i])
			print sample_string

	def time2str(self,current_time):
		'''Convert a floating point time into human readable form'''
		secs, usecs = "{:0.06f}".format(current_time).split('.')
		time_struct = time.localtime(int(secs))
		return (time.strftime("%Y-%m-%d %H:%M:%S.", time_struct) +
		    "{:06d}".format(int(usecs)))

	def get_elapsed_time(self, first_seconds, first_sequence):
		'''Given starting counters and current timestamp, show time since start_time.'''
		elapsed_samples = (
		    (self.seconds * self.samples_per_second + self.sample_count)
		    - (first_seconds * self.samples_per_second + first_sequence))
		return float(elapsed_samples) /  float(self.samples_per_second)
