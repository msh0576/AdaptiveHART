#from TOSSIM import Tossim
from random import *
#from TestNetworkMsg import *
import socket
import sys

enable_main=0;
if enable_main:
	def main():
		rssi_level=sys.argv[1]

		return {'y0':rssi_level}
		rssi_level=int(main()['y0'])


else:
	noise_offset = 7





sock=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#sock.connect(('192.168.0.13',55000))
sock.connect(('127.0.0.1',10035))


sock.send("0".encode())
i=0
for i in range(10):
    #z = input("Enter something for the server: ")
    #sock.send(z.encode('utf-8'))
    # Halts
    str_i=str(i)
    sock.send(str_i.encode())
    #print ('[Waiting for response...]')
    print ((sock.recv(1024)).decode('utf-8'))
'''

try:
	message = '0';
	sock.sendall(message)
	amount_received = 0
	amount_expected = len(message)
	while amount_received < amount_expected:
		data = sock.recv(90)
		if data:
			amount_received += len(data)
			print data

finally:
    sock.close()

'''
