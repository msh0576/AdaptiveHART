#!/usr/bin/env python
from TOSSIM import Tossim
from random import *
from TestNetworkMsg import *
import sys
import socket
import os
import time
import VCS_algorithm

def extract_info(string):
	'''
	receive some information from matalb app
	it contains "finish_flag disturbance_instant_P1"
	outputs: int(finish_flag), int(disturbance_instant_P1)
	'''
	args = string.split()
	return int(args[0])

def init_disturbance_second(disturbance_time):
	'''
	initialize 'dist_sec' variable with first disturbacne instant from matlab
	'''
	global dist_sec, dist_sec_flag

	if dist_sec_flag == False:
		dist_sec = disturbance_time
		dist_sec_flag = True

def is_actuation_interval_changed(flow_info, disturbance_sec):
	'''
	if actuation interval is changed due to disturbance,
	then the value is stored in global variable 'broad_intv'
	'''
	global prev_pkt_arriv_inst, broad_intv
	time = t.timeStr()
	[Hour, Min, Sec] = time.split(':')
	Sec = round(float(Sec),2)
	#print("disturbance_sec: ", disturbance_sec)
	#print("Sec: ", Sec)

	# compute actuation_interval
	actu_intv = Sec - prev_pkt_arriv_inst

	# confirm actuation interval follows the changed network parameter
	task_period = Task_periods[flow_info['flowid']-1] * 0.01
	#disturbance_time = disturbance_time/100	# simulation time -> second
	if Sec >= disturbance_sec:
		if  (task_period + 0.02) >= actu_intv and flow1_info['flag'] == False:
			broad_intv = round((Sec - disturbance_sec),2)
			flow1_info['flag'] = True
	prev_pkt_arriv_inst = Sec
	#print("broad_intv:", broad_intv)

### global variable ###
broad_intv = 0
prev_pkt_arriv_inst = 0
flow1_info = {'flowid':1, 'flag': False}
dist_sec_flag = False
dist_sec = 0
#######################

enable_main=0;
if enable_main:
	def main():
		rssi_level=sys.argv[1]
		return {'y0':rssi_level}
	rssi_level=int(main()['y0'])
else:
	### Topology -60dBm (power) ###
    #noise_offset = 1 #PDR:91%
	#noise_offset = 10 #PDR:85%
	#noise_offset = 20 #PDR:75%
	#noise_offset = 21 #PDR:68%
	#noise_offset = 22 #PDR:60%
	#noise_offset = 23 #PDR:47%
	#noise_offset = 25 #PDR:11%
    #noise_offset = 30 #PDR:0%
	### Topology -70dBm ###
	#noise_offset = 20 #PDR:0%
	#noise_offset = 10 #PDR:75%

	### Revised version -- CpmModelC.nc -- eliminating checkReceive() function ###
	### Default channel: -91dBm ###
	### Topology -60dBm (power) ###
	#noise_offset = 1 #PDR:95%
	noise_offset = 15 #PDR:90%
	#noise_offset = 22 #PDR:77%
	#noise_offset = 23 #PDR:68%
	#noise_offset = 24 #PDR:52%
	#noise_offset = 25 #PDR:32%

t = Tossim([])

''' Debug '''
#t.addChannel("receive_ack", sys.stdout)
#t.addChannel("test", sys.stdout)
#t.addChannel("ScheduleConfig", sys.stdout)
#t.addChannel("CpmModelC", sys.stdout)
#t.addChannel("TossimPacketModelC", sys.stdout)
#t.addChannel("SimMoteRadioChannel", sys.stdout)
#t.addChannel("Gain", sys.stdout)
#t.addChannel("receive_power", sys.stdout)
#t.addChannel("SimMote_power", sys.stdout)
#t.addChannel("AM", sys.stdout)
#t.addChannel("Insert", sys.stdout)
t.addChannel("Task_T_Test", sys.stdout)
#t.addChannel("VCStest", sys.stdout)
#t.addChannel("receive", sys.stdout)
#t.addChannel("transmission", sys.stdout)
#t.addChannel("PHY_layer_check", sys.stdout)
t.addChannel("E2E_delay_Log_data", sys.stdout)
#t.addChannel("check_link_quality", sys.stdout)
#t.addChannel("Util_Log_data", sys.stdout)
#t.addChannel("CpmModelC__", sys.stdout)
#t.addChannel("PDR_trace", sys.stdout)


#Log Data
#Log = open("log.txt", "w")
#t.addChannel('radio_send', Log)

### Test VCS_algorithm	###
send_to_MAClayer = []
send_to_MAClayer = VCS_algorithm.Execution_func()

### Get UUnifast results ###
# Python to mote #
# Input:(Task1_T, Task2_T, ...)
print("Ok...")
if len(sys.argv) >= 4:
	Task_periods_orig = []
	Task_maxTx_orig = []
	for Z in range(1,len(sys.argv)):
		if Z%2 == 1:
			Task_periods_orig.append(int(sys.argv[Z]))
		else:
			Task_maxTx_orig.append(int(sys.argv[Z]))
	t.sendTaskPeriods(Task_periods_orig[0], Task_periods_orig[1], 0, 0)
	t.sendNumTx(Task_maxTx_orig[0], Task_maxTx_orig[1], 0, 0)
else:
	print("No parameter has been included")
	exit(1)

### Python to mote ###
# Input: (nodeid, TxOffset, 0, 0)
for seq in send_to_MAClayer:
	t.sendVirtualSchedule(seq[0], seq[1], 0, 0)

Task_periods = Task_periods_orig
Task_maxTx = Task_maxTx_orig

Task_periods_dist = [11, 11]
Task_maxTx_interf = [2, 2]


r = t.radio()
L=list()
nodes = [1, 2, 3, 4, 5, 6, 51, 52]
for channel_1 in [22, 23, 24, 25, 26]:
	channel=channel_1
	neignbour_strength=-20;
	sync_rssi_strength=-10
	sync_rssi_strength_2 = -30


	for sensor in nodes:		# Set network topology
		r.add(sensor, 100, sync_rssi_strength-300, channel_1)	#add(source, destination, gain)
		r.add(100, sensor, sync_rssi_strength, channel_1)

		'''
		if sensor == 1:
			r.add(sensor, 100, sync_rssi_strength, channel_1)	#add(source, destination, gain)
			r.add(100, sensor, sync_rssi_strength, channel_1)
		elif sensor == 2:
			r.add(sensor, 100, sync_rssi_strength_2, channel_1)	#add(source, destination, gain)
			r.add(100, sensor, sync_rssi_strength_2, channel_1)
		elif sensor == 10:
			r.add(sensor, 100, sync_rssi_strength_2, channel_1)	#add(source, destination, gain)
			r.add(100, sensor, sync_rssi_strength_2, channel_1)
		'''


for channel in [22, 23, 24, 25, 26]:
	if channel == 22:
		f = open("topo_rssis_ch_22_ex2.txt", "r")##topo and RSSI strength
		for line in f:
			s = line.split()
			if s:
				#print " ", s[0], " ", s[1], " ", s[2];
				r.add(int(s[0]), int(s[1]), float(s[2]) - 4, channel)##Topos in two channels are the same. RSSI different--yh
	elif channel == 23:
		f = open("topo_rssis_ch_23_ex2.txt", "r")
		for line in f:
			s = line.split()
			if s:
				#print " ", s[0], " ", s[1], " ", s[2];
				r.add(int(s[0]), int(s[1]), float(s[2]) - 4, channel)##It seems that the r.add is modified by Bo--yh
	else:
		f = open("topo_rssis_ch_22_ex2.txt", "r")
		for line in f:
			s = line.split()
			if s:
				#print " ", s[0], " ", s[1], " ", s[2];
				r.add(int(s[0]), int(s[1]), float(s[2]) - 4, channel)##It seems that the r.add is modified by Bo--yh


Allnodes = [100]
Allnodes = Allnodes + nodes
for node in Allnodes:
	m = t.getNode(node);
	for channel in [22, 23, 24, 25, 26]:
		if channel==22:
			noise = open("noise_ch_22_26_1000.txt", "r")	# Average -46dBm
			lines = noise.readlines()
		elif channel==23:
			noise = open("noise_ch_23_26_1000.txt", "r")
			lines = noise.readlines()
		for line in lines:
			strrr = line.strip()
			if (strrr != ""):
				val = int(strrr) + noise_offset
				#print("00000000")
				m.addNoiseTraceReading(val-45, channel)
				#print("11111111111")
		#print("222222")
		m.createNoiseModel(channel)
		#print("333333")
	m.turnOn()
	m.bootAtTime(0)
	#print "Booting ", node, " at time ", str(0)


### Simulink connection ###
# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
#server_address = ('localhost', 10032)
server_address = ('127.0.0.1', 10035)
print >>sys.stderr, 'starting up on %s port %s' % server_address
sock.bind(server_address)
sock.listen(1)


run_count = 1;
#0 means not received.
Interference_time = 1000	# 100=>1s  , 1=>10ms
Interference_finish = 1500
Disturbance_time = 1000
Disturbance_finish = 1500
interf_flag = 0
interf_handle_flag = 0
dist_flag = 0
dist_time = t.timeStr() # for checking broadcast_interval
while True:
	connection, client_address = sock.accept()
	try:
	    # print >>sys.stderr, 'Client call, No.', run_count
		while True:
			data = connection.recv(30)
			if data:
				# extract received info
				finish_flag = extract_info(data)
				# Wireless Interference
				if t.time() > 97656250*Interference_time and t.time() < 97656250*Interference_finish and interf_flag == 0:
					noise_offset = 22
					for node in Allnodes:
						m = t.getNode(node);
						for channel in [22, 23, 24, 25, 26]:
							if channel==22:
								noise = open("noise_ch_22_26_1000.txt", "r")	# Average -46dBm
								lines = noise.readlines()
							elif channel==23:
								noise = open("noise_ch_23_26_1000.txt", "r")
								lines = noise.readlines()
							for line in lines:
								strrr = line.strip()
								if (strrr != ""):
									val = int(strrr) + noise_offset
									m.addNoiseTraceReading(val-45, channel)
							m.createNoiseModel(channel)
					interf_flag = 1
				# Interference handle
				elif t.time() > 97656250*(Interference_time+0) and t.time() < 97656250*Interference_finish and interf_handle_flag == 0:
					interf_handle_flag = 1
					#Task_maxTx = Task_maxTx_interf
					# Send a Interference signal to MAC Layer
					#t.sendNumTx(Task_maxTx[0], Task_maxTx[1], 0, interf_flag)
				# Wireless Interference Finish
				elif t.time() > 97656250*Interference_finish and interf_flag == 1:
					noise_offset = 8
					for node in Allnodes:
						m = t.getNode(node);
						for channel in [22]:
							if channel==22:
								noise = open("noise_ch_22_26_1000.txt", "r")	# Average -46dBm
								lines = noise.readlines()
							for line in lines:
								strrr = line.strip()
								if (strrr != ""):
									val = int(strrr) + noise_offset
									m.addNoiseTraceReading(val-45, channel)
							m.createNoiseModel(channel)
					interf_flag = 0
				# Interference Finish handle
				elif t.time() > 97656250*(Interference_finish+0) and interf_handle_flag == 1:
					interf_handle_flag = 0;
					#Task_maxTx = Task_maxTx_orig
					# Send a Interference signal to MAC Layer
					#t.sendNumTx(Task_maxTx[0], Task_maxTx[1], 0, interf_flag)

				# Disturbances
				if t.time() > 97656250*Disturbance_time and t.time() < 97656250*Disturbance_finish and dist_flag == 0:
					dist_flag = 1
					#Task_periods = Task_periods_dist
					# Send a Disturbancd signal to MAC Layer
					#t.sendTaskPeriods(Task_periods[0], Task_periods[1], 0, dist_flag)
				# Disturbnace finish
				elif t.time() > 97656250*Disturbance_finish and dist_flag == 1:
					dist_flag = 0
					#Task_periods = Task_periods_orig
					# Send a Disturbancd signal to MAC Layer
					#t.sendTaskPeriods(Task_periods[0], Task_periods[1], 0, dist_flag)

				#############################
				# Execute 10ms
				if run_count % 18 == 0:
					m = t.getNode(11);

				rcvedlist = [0, 0, 0, 0, 0, 0, 0, 0]
				while (t.time() <= 97656250*run_count): # here the 97656250 represents 10ms
					rcved = t.runNextEvent()
					#print("rcved:",rcved)
					if rcved == 2:		# 0000 0010 - flowid:1
						rcvedlist[0] = 1; # flow 1 has been received through the WSN
						is_actuation_interval_changed(flow1_info, dist_sec)
					elif rcved == 4:	# 0000 0100 - flowid:2
						rcvedlist[1] = 1; # flow 2 has been received through the WSN
					elif rcved == 8:
						rcvedlist[2] = 1;
					elif rcved == 16:
						rcvedlist[3] = 1;
					elif rcved == 32:
						rcvedlist[4] = 1;
					elif rcved == 64:
						rcvedlist[5] = 1;
					elif rcved == 128:
						rcvedlist[6] = 1;
					elif rcved == 256:
						rcvedlist[7] = 1;
				rcvedlist[4] = broad_intv	# temparaly, broadcasting interval
				rcvedlist[5] = (-46-45)+noise_offset	# temparaly, Noise level
				rcvedlist[6] = Task_maxTx[0]	# temparaly, Task1 max Tx
				rcvedlist[7] = Task_periods[0]	# temparaly, T1 Period
				#print("rcvedList:",rcvedlist)
				run_count = run_count + 1;
				reception = str(rcvedlist[0]) + ',' + str(rcvedlist[1]) + ',' + str(rcvedlist[2]) + ',' + str(rcvedlist[3]) + \
				',' + str(rcvedlist[4]) + ',' + str(rcvedlist[5]) + ',' + str(rcvedlist[6]) + ',' + str(rcvedlist[7]);
				#print reception
				connection.sendall(reception)
				if finish_flag == 1:	# Simulink finish
					connection.close()
					exit(0)
			else:
				break
	finally:
		connection.close()
