#!/usr/bin/env python
from TOSSIM import Tossim
from random import *
from TestNetworkMsg import *
import sys
import socket

enable_main=0;
if enable_main:
	def main():
		rssi_level=sys.argv[1]
		print("rssi_level:%s"%(rssi_level))
		return {'y0':rssi_level}
		rssi_level=int(main()['y0'])


else:
	noise_offset = 7

# Check inputs from matlab

rssi_level = 0
finish_flag = 0
if len(sys.argv) >= 4:
	rssi_level=sys.argv[1]
	finish_flag = sys.argv[2]
	dist_inst_P1 = sys.argv[3]
	dist_finish_P1 = sys.argv[4]


#print("sys.argv[2]:%s"%(sys.argv[2]))
#print("sys.argv[3]:%s"%(sys.argv[3]))
# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#server_address = ('localhost', 10032)
server_address = ('127.0.0.1', 10035)
sock.connect(server_address)

try:
	message = str(finish_flag + " " + dist_inst_P1 + " " + dist_finish_P1);
	sock.sendall(message)
	amount_received = 0
	amount_expected = len(message)
	while amount_received < amount_expected:
		data = sock.recv(128)
		if data:
			amount_received += len(data)
			print data
finally:
    sock.close()
