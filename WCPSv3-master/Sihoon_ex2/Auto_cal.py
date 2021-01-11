#!/usr/bin/env python

# Initilize file name that extract log data at
file_name = []
file_path = "/home/sihoon/WCPSv3-master/Sihoon_ex2/Log_file/"

result_file_name = "Result.txt"
result_file_path = "/home/sihoon/WCPSv3-master/Sihoon_ex2/Result_file/"

FILE_NUMBER = 100    # Test0.txt ~ Test99.txt
for file_idx in range(FILE_NUMBER):
    tmp_name = "Test"+str(file_idx)+".txt"
    #print("tmp_name:%s"%(tmp_name))
    file_name.append(tmp_name)



# Index
NODEID = 0
FLOWID = 1
RCV_COUNT = 2
SUPERFRAME_LEN = 16     # check slot0 ~ slot19

# receive node id
Task1_destination = 51        # topology: 1->3->4->51
Task2_destination = 52        # topology: 2->3->4->52

Task1_relay1 = 3
Task2_relay1 = 3

# Task id
Hi_task_id = 1
Lo_task_id = 2

# delete content of a file
def deleteContent(fName):
    with open(fName,'w'):
        pass

# Initilize a Result file and log data files
deleteContent(result_file_path + result_file_name)

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
    Task1_e2e_rcv_count = 0
    Task2_e2e_rcv_count = 0
    Task1_e2e_delay = [0 for _ in range(SUPERFRAME_LEN)]        # e2e delay boundary : slot0 ~ slot19
    Task2_e2e_delay = [0 for _ in range(SUPERFRAME_LEN)]        # e2e delay boundary : slot0 ~ slot19
    Task2_relay1_rcv_count_for_task1 = 0
    Task2_relay1_rcv_count_for_task2 = 0

    lines = f.readlines()
    # Store last line Data in a file
    for line in lines:
        # file each line: Node id, flow id, rcv_count, rcv_count_at_slot1, rcv_count_at_slot2, rcv_count_at_slot3, rcv_count_at_slot4, rcv_count_at_slot5, rcv_count_at_slot6, rcv_count_at_slot7, rcv_count_at_slot8, rcv_count_at_slot9
        line_list = line.split()
        if line_list:
            # cheack node id
            if line_list[NODEID] == str(Task1_destination):
                '''
                Task1_e2e_rcv_count = line_list[RCV_COUNT]     # receive packet count
                for slot in range(SUPERFRAME_LEN):
                    Task1_e2e_delay[slot] = (line_list[3 + slot])
                '''
            elif line_list[NODEID] == str(Task2_destination):
                if line_list[FLOWID] == str(Lo_task_id):
                    Task2_e2e_rcv_count = line_list[RCV_COUNT]
                    for slot in range(SUPERFRAME_LEN):
                        Task2_e2e_delay[slot] = (line_list[3 + slot])


    # File Close
    f.close()

    # Store total result in a file
    result_f = open(result_file_path + result_file_name, 'a')
    #result_f.write("Task1_e2e_rcv_count, slot0~11: %s %s %s %s %s %s %s %s %s %s %s %s %s \n"%( Task1_e2e_rcv_count, Task1_e2e_delay[0], Task1_e2e_delay[1], Task1_e2e_delay[2], Task1_e2e_delay[3], Task1_e2e_delay[4], Task1_e2e_delay[5], Task1_e2e_delay[6], Task1_e2e_delay[7], Task1_e2e_delay[8], Task1_e2e_delay[9], Task1_e2e_delay[10], Task1_e2e_delay[11]))
    result_f.write("Task2_e2e_rcv_count, slot0~15: %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s\n"%( Task2_e2e_rcv_count, Task2_e2e_delay[0], Task2_e2e_delay[1], Task2_e2e_delay[2], Task2_e2e_delay[3], Task2_e2e_delay[4], Task2_e2e_delay[5], Task2_e2e_delay[6], Task2_e2e_delay[7], Task2_e2e_delay[8], Task2_e2e_delay[9], Task2_e2e_delay[10], Task2_e2e_delay[11], Task2_e2e_delay[12], Task2_e2e_delay[13], Task2_e2e_delay[14], Task2_e2e_delay[15]))
    #result_f.write("Relay ID, rcv_task1, rcv_task2: %s %s %s\n", Task2_relay1, Task2_relay1_rcv_count_for_task1, Task2_relay1_rcv_count_for_task2)
    #print("3_rcv_count, 5_rcv_count, 7_rcv_count, 51_rcv_count, slot1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12: %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s"%(relay1_rcv_count, relay2_rcv_count, relay3_rcv_count, total_e2e_dest_rcv_count, total_e2e_delay[1], total_e2e_delay[2], total_e2e_delay[3], total_e2e_delay[4], total_e2e_delay[5], total_e2e_delay[6], total_e2e_delay[7], total_e2e_delay[8], total_e2e_delay[9], total_e2e_delay[10], total_e2e_delay[11], total_e2e_delay[12]))

    result_f.close()
