#!/usr/bin/env python
import commands
import sys

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

def Response_99(resp_dist):
    Accum_prob = 0
    slot = 0
    for idx in range(len(resp_dist)):
        Accum_prob = Accum_prob + resp_dist[idx]
        if Accum_prob >= 0.99:
            slot = idx+1
            break
    return slot*10

# Initilize file name that extract log data at
file_name = []
file_path = "/home/sihoon/WCPSv3-master/Sihoon_ex2/Log_file/"

result_file_name = "E2EDelay_Result.txt"
result_file_path = "/home/sihoon/WCPSv3-master/Sihoon_ex2/Result_file/"

average_file_name = "Average.txt"
average_file_path = "/home/sihoon/WCPSv3-master/Sihoon_ex2/Result_file/"

### Task Period Setting ###
# it should be harmonic of all task periods
Each_task_T = [15, 15]
Task_ReTx = [3, 3]

### Initilization ###
# Index
NODEID = 0
FLOWID = 1
RCV_COUNT = 2
TX_COUNT = 3
SUPERFRAME_LEN = lcm(Each_task_T[0], Each_task_T[1])     # check slot0 ~ slot19
SUPERFRAME_LEN = Each_task_T[1]
# receive node id
Task1_destination = 51        # topology: 1->3->4->51
Task2_destination = 52        # topology: 2->3->4->52

# Task id
Hi_task_id = 1
Lo_task_id = 2

TOSSIM_simulation_times = 100;


### Execute TOSSIM and store the result ###
deleteContent(result_file_path + result_file_name)

result_f = open(result_file_path + result_file_name, 'a')
result_f.write("Each Task Period:%s\n\n"%(Each_task_T))
result_f.write("Task_ReTx:%s\n\n"%(Task_ReTx))
result_f.close()

print("Each Task Period:%s"%(Each_task_T))
print("SUPERFRAME_LEN:%s"%(SUPERFRAME_LEN))


for N in range(TOSSIM_simulation_times):
    exe_file_name = "Test"+str(N)+".txt"
    deleteContent(file_path + exe_file_name)
    print(exe_file_name)
    fail, output = commands.getstatusoutput("python tossim-event-server.py" +" "+str(Each_task_T[0])+" "+str(Task_ReTx[0])+" "+str(Each_task_T[1])+" "+str(Task_ReTx[1]) + " >>"+str(file_path)+str(exe_file_name))
    #fail, output = commands.getstatusoutput("python tossim-event-server.py>>"+str(file_path)+str(exe_file_name))
    faile_check(fail)
    #print output

### Gather results from N Test files to a file ###
file_name = []
for file_idx in range(TOSSIM_simulation_times):
    tmp_name = "Test"+str(file_idx)+".txt"
    #print("tmp_name:%s"%(tmp_name))
    file_name.append(tmp_name)


Task2_e2e_delay_aver = [0 for _ in range(SUPERFRAME_LEN)]
Task2_e2e_delay_percentage = [0 for _ in range(SUPERFRAME_LEN)]
Task2_e2e_rcv_count_aver = 0
Task2_e2e_tx_count_aver = 0

# Extract e2e delay distribution in a result and accumulate it
for fname in file_name:
    # Check file existance
    try:
        f = open(file_path + fname,'r')
    except:
        print("No file:%s"%(fname))
        exit(1)

    # total result variable
    Task1_e2e_rcv_count = 0
    Task2_e2e_rcv_count = 0
    Task1_e2e_tx_count = 0
    Task2_e2e_tx_count = 0
    Task1_e2e_delay = [0 for _ in range(SUPERFRAME_LEN)]        # e2e delay boundary : slot0 ~ slot19
    Task2_e2e_delay = [0 for _ in range(SUPERFRAME_LEN)]        # e2e delay boundary : slot0 ~ slot19
    lines = f.readlines()
    # Store last line Data in a file
    for line in lines:
        # file each line: Node id, flow id, rcv_count, rcv_count_at_slot1, rcv_count_at_slot2, rcv_count_at_slot3, rcv_count_at_slot4, rcv_count_at_slot5, rcv_count_at_slot6, rcv_count_at_slot7, rcv_count_at_slot8, rcv_count_at_slot9
        line_list = line.split()
        if line_list:
            # cheack node id
            if line_list[NODEID] == str(Task1_destination):
                pass
            elif line_list[NODEID] == str(Task2_destination):
                if line_list[FLOWID] == str(Lo_task_id):
                    Task2_e2e_rcv_count = line_list[RCV_COUNT]
                    Task2_e2e_tx_count = line_list[TX_COUNT]
                    for slot in range(SUPERFRAME_LEN):
                        Task2_e2e_delay[slot] = (line_list[4 + slot])
    # File Close
    f.close()

    # Accumulate e2e_delay results
    for s in range(SUPERFRAME_LEN):
        Task2_e2e_delay_aver[s] = Task2_e2e_delay_aver[s] + int(Task2_e2e_delay[s])
    Task2_e2e_rcv_count_aver = Task2_e2e_rcv_count_aver + int(Task2_e2e_rcv_count)
    Task2_e2e_tx_count_aver = Task2_e2e_tx_count_aver + int(Task2_e2e_tx_count)

# Average N simulation results
Task2_e2e_rcv_count_aver = float(Task2_e2e_rcv_count_aver)/float(TOSSIM_simulation_times)
Task2_e2e_tx_count_aver = float(Task2_e2e_tx_count_aver)/float(TOSSIM_simulation_times)
for idx in range(SUPERFRAME_LEN):
    Task2_e2e_delay_aver[idx] = float(Task2_e2e_delay_aver[idx])/float(TOSSIM_simulation_times)
    Task2_e2e_delay_percentage[idx] = (Task2_e2e_delay_aver[idx]/Task2_e2e_rcv_count_aver)

print("Task2_e2e_tx_count_aver: %s"%(Task2_e2e_tx_count_aver))
print("Task2_e2e_rcv_count_aver: %s"%(Task2_e2e_rcv_count_aver))
print("Task2_e2e_delay_percentage: "),
for idx in range(SUPERFRAME_LEN):
    print("%s "%(Task2_e2e_delay_percentage[idx])),
print("")
print("Response_99:%s"%(Response_99(Task2_e2e_delay_percentage)))
