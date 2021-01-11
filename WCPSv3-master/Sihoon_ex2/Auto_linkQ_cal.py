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
TXCOUNT = 1
RXCOUNT = 1

# node id in a link
SenderID = 2
ReceverID = 3

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
    Tx_attempt = 0;
    Rx_count = 0;


    lines = f.readlines()
    # Store last line Data in a file
    for line in lines:
        # file each line: Node id, flow id, rcv_count, rcv_count_at_slot1, rcv_count_at_slot2, rcv_count_at_slot3, rcv_count_at_slot4, rcv_count_at_slot5, rcv_count_at_slot6, rcv_count_at_slot7, rcv_count_at_slot8, rcv_count_at_slot9
        line_list = line.split()
        if line_list:
            # cheack node id
            if line_list[NODEID] == str(SenderID):
                Tx_attempt = line_list[TXCOUNT]     # receive packet count
            elif line_list[NODEID] == str(ReceverID):
                Rx_count = line_list[RXCOUNT]


    # File Close
    f.close()

    # Store total result in a file
    result_f = open(result_file_path + result_file_name, 'a')
    result_f.write("Tx_attemp, Rx_count: %s %s \n"%(Tx_attempt, Rx_count))

    #print("3_rcv_count, 5_rcv_count, 7_rcv_count, 51_rcv_count, slot1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12: %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s"%(relay1_rcv_count, relay2_rcv_count, relay3_rcv_count, total_e2e_dest_rcv_count, total_e2e_delay[1], total_e2e_delay[2], total_e2e_delay[3], total_e2e_delay[4], total_e2e_delay[5], total_e2e_delay[6], total_e2e_delay[7], total_e2e_delay[8], total_e2e_delay[9], total_e2e_delay[10], total_e2e_delay[11], total_e2e_delay[12]))

    result_f.close()
