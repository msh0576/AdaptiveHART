#!/usr/bin/env python
import commands
import sys
import pandas as pd
import numpy as np


### This file is based on a file ScheduleRatio.py


def gcd(a,b):
    """Compute the greatest common divisor of a and b"""
    while b > 0:
        a, b = b, a % b
    return a

def lcm(a, b):
    """Compute the lowest common multiple of a and b"""
    return a * b / gcd(a, b)

# Execute txt file
def faile_check(fail):
	if fail:
		print 'Failed\n'
		sys.exit(1)

# Input: Each task utilization, Each task execution time
# Output: Each task periods
def Task_Periods(Each_task_U, Each_task_C):
	Task1_U = float(Each_task_U[0])
	Task2_U = float(Each_task_U[1])
	Task1_C = float(Each_task_C[0])
	Task2_C = float(Each_task_C[1])

	Task1_T = int(round(Task1_C / Task1_U))
	Task2_T = int(round(Task2_C / Task2_U))

	return [Task1_T, Task2_T]


# delete content of a file
def deleteContent(fName):
	with open(fName,'w'):
		pass

# Initilize file name that extract log data at
file_name = []
file_path = "/home/sihoon/WCPSv3-master/Sihoon_ex2/Log_file/"

result_file_name = "EVMA_PDR.txt"
result_file_path = "/home/sihoon/WCPSv3-master/Sihoon_ex2/Result_file/"

average_file_name = "Average.txt"
average_file_path = "/home/sihoon/WCPSv3-master/Sihoon_ex2/Result_file/"


### Execute TOSSIM and store the result ###
Each_task_T = [50, 50]

# Index
NODEID = 0
FLOWID = 1
MISS_COUNT = 2
TX_COUNT = 3

# receive node id
Task1_destination = 51
Task2_destination = 52

# Task id
Hi_task_id = 1
Lo_task_id = 2


deleteContent(result_file_path + result_file_name)

result_f = open(result_file_path + result_file_name, 'a')
result_f.write("Each Task Period:%s\n\n"%(Each_task_T))
result_f.close()

print("Each Task Period:%s"%(Each_task_T))


### Execute TOSSIM N times
TOSSIM_simulation_times = 100;
for N in range(TOSSIM_simulation_times):
	exe_file_name = "Test"+str(N)+".txt"
	deleteContent(file_path + exe_file_name)
	fail, output = commands.getstatusoutput("python tossim-event-server.py" +" "+str(Each_task_T[0])+" "+str(Each_task_T[1]) + " >>"+str(file_path)+str(exe_file_name))
	#fail, output = commands.getstatusoutput("python tossim-event-server.py>>"+str(file_path)+str(exe_file_name))
	faile_check(fail)
    #print output
