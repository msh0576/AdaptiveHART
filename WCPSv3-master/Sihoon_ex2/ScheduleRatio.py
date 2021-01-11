#!/usr/bin/env python
import commands
import sys

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

result_file_name = "Result.txt"
result_file_path = "/home/sihoon/WCPSv3-master/Sihoon_ex2/Result_file/"


### Generate Task Periods from an UUnifast result ###
uunifast_fname = "UUnifast_U3.0.txt"
try:
	u_f = open(uunifast_fname, "r")
except:
	print("No file:%s"%(uunifast_fname))
	exit(1)

### Initilization ###
# Index
NODEID = 0
FLOWID = 1
# Version1: Check e2e delay
RCV_COUNT = 2
SUPERFRAME_LEN = 16     # check slot0 ~ slot19
# Version2: Check Schedule ratio
MISS_COUNT = 2
TOTAL_TX_COUNT = 3


# receive node id
Task1_destination = 51        # topology: 1->3->4->51
Task2_destination = 52        # topology: 2->3->4->52


# Task id
Hi_task_id = 1
Lo_task_id = 2


# Extract utilizations for each task
u_lines = u_f.readlines()
Total_Utilization = 1
Total_Task = 2
Task_Set_count = 0
Each_task_C = [12, 12]	# Worst-case Execution time
Each_task_U = []
Utilization_count = 0
for u_line in u_lines:
	u_line_list = u_line.split()
	if u_line_list:
		if u_line_list[0] == "Task" and u_line_list[1] == "Set":	# Check the start line
			Each_task_U = []
			Task_Set_count = u_line_list[3]
		else:
			Each_task_U.append(u_line_list[1])
			if len(Each_task_U) == Total_Task:
				#print("Execute a TOSSIM with %s"%(Each_task_U))
				Each_task_T = Task_Periods(Each_task_U, Each_task_C)
				print("Each Task Period:%s"%(Each_task_T))


				result_file_name = "Result" + str(Utilization_count) + ".txt"
				# Initilize a Result file and log data files
				deleteContent(result_file_path + result_file_name)

				result_f = open(result_file_path + result_file_name, 'a')
				result_f.write("Each Task Period:%s\n\n"%(Each_task_T))
				result_f.close()


				### Execute TOSSIM N times
				TOSSIM_simulation_times = 100;
				for N in range(TOSSIM_simulation_times):
					exe_file_name = "Test"+str(N)+".txt"
					deleteContent(file_path + exe_file_name)
					fail, output = commands.getstatusoutput("python tossim-event-server.py" +" "+str(Each_task_T[0])+" "+str(Each_task_T[1]) + " >>"+str(file_path)+str(exe_file_name))
					#fail, output = commands.getstatusoutput("python tossim-event-server.py>>"+str(file_path)+str(exe_file_name))
					faile_check(fail)
				    #print output

				### Gather outputs from N Test files to a file
				file_name = []
				for file_idx in range(TOSSIM_simulation_times):
				    tmp_name = "Test"+str(file_idx)+".txt"
				    #print("tmp_name:%s"%(tmp_name))
				    file_name.append(tmp_name)




				# Repeat in file_name[]
				# Extract essential data in a simulation
				for fname in file_name:
				    # Check file existance
				    try:
				        f = open(file_path + fname,'r')
				    except:
				        print("No file:%s"%(fname))
				        exit(1)

				    # total result variable
					Task1_Miss_count = 0
					Task2_Miss_count = 0
					Task1_Total_Tx_count = 0
					Task2_Total_Tx_count = 0

				    lines = f.readlines()
				    # Store last line Data in a file
				    for line in lines:
				        # file each line: Node id, flow id, rcv_count, rcv_count_at_slot1, rcv_count_at_slot2, rcv_count_at_slot3, rcv_count_at_slot4, rcv_count_at_slot5, rcv_count_at_slot6, rcv_count_at_slot7, rcv_count_at_slot8, rcv_count_at_slot9
				        line_list = line.split()
				        if line_list:
							# check node id
							if line_list[NODEID] == str(Task1_destination):
								Task1_Miss_count = line_list[MISS_COUNT]
								Task1_Total_Tx_count = line_list[TOTAL_TX_COUNT]
							elif line_list[NODEID] == str(Task2_destination):
								Task2_Miss_count = line_list[MISS_COUNT]
								Task2_Total_Tx_count = line_list[TOTAL_TX_COUNT]


				    # File Close
				    f.close()

				    # Store total result in a file
				    result_f = open(result_file_path + result_file_name, 'a')
				    #result_f.write("Task1_e2e_rcv_count, slot0~11: %s %s %s %s %s %s %s %s %s %s %s %s %s \n"%( Task1_e2e_rcv_count, Task1_e2e_delay[0], Task1_e2e_delay[1], Task1_e2e_delay[2], Task1_e2e_delay[3], Task1_e2e_delay[4], Task1_e2e_delay[5], Task1_e2e_delay[6], Task1_e2e_delay[7], Task1_e2e_delay[8], Task1_e2e_delay[9], Task1_e2e_delay[10], Task1_e2e_delay[11]))
				    #result_f.write("Task2_e2e_rcv_count, slot0~15: %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s\n"%( Task2_e2e_rcv_count, Task2_e2e_delay[0], Task2_e2e_delay[1], Task2_e2e_delay[2], Task2_e2e_delay[3], Task2_e2e_delay[4], Task2_e2e_delay[5], Task2_e2e_delay[6], Task2_e2e_delay[7], Task2_e2e_delay[8], Task2_e2e_delay[9], Task2_e2e_delay[10], Task2_e2e_delay[11], Task2_e2e_delay[12], Task2_e2e_delay[13], Task2_e2e_delay[14], Task2_e2e_delay[15]))
				    result_f.write("Task1- MissCount, TotalTxCount: %s %s\n"%(Task1_Miss_count, Task1_Total_Tx_count))
				    result_f.write("Task2- MissCount, TotalTxCount: %s %s\n"%(Task2_Miss_count, Task2_Total_Tx_count))
				    result_f.close()

				Utilization_count = Utilization_count + 1

u_f.close()
