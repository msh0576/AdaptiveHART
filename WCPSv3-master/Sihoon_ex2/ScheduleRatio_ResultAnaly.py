#!/usr/bin/env python
import commands
import sys


# Execute txt file
def faile_check(fail):
	if fail:
		print 'Failed\n'
		sys.exit(1)

final_result_file_path = "/home/sihoon/WCPSv3-master/Sihoon_ex2/Result_file/"

Utilization = 3.0
result_file_path = "/home/sihoon/WCPSv3-master/Sihoon_ex2/Result_file/U"+str(Utilization)+"/"

file_total_number = 100
Unschedulable_count = 0

TASK_ID = 0
MISS_COUNT = 3
TX_COUNT = 4
for N in range(file_total_number):
    result_file_name = "Result"+str(N)+".txt"

    try:
    	r_f = open(result_file_path + result_file_name, "r")
    except:
    	print("No file:%s"%(result_file_name))
    	exit(1)

    # Average for a result file
    T1_miss_count = 0
    T2_miss_count = 0
    T1_tx_count = 0
    T2_tx_count = 0
    T1_count = 0
    T2_count = 0
    T1_miss_count_aver = 0
    T2_miss_count_aver = 0
    T1_Dead_satis_prob = 0
    T2_Dead_satis_prob = 0


    r_lines = r_f.readlines()
    for r_line in r_lines:
		line_list = r_line.split()
		if line_list:
			if line_list[TASK_ID] == "Task1-":
				T1_miss_count = T1_miss_count + float(line_list[MISS_COUNT])
				T1_tx_count = float(line_list[TX_COUNT])
				T1_count = T1_count + 1
			elif line_list[TASK_ID] == "Task2-":
				T2_miss_count = T2_miss_count + float(line_list[MISS_COUNT])
				T2_tx_count = float(line_list[TX_COUNT])
				T2_count = T2_count + 1

    T1_miss_count_aver = T1_miss_count/float(T1_count)
    T2_miss_count_aver = T2_miss_count/float(T2_count)
    print("T1_miss_count_aver:%s    T2_miss_count_aver:%s"%(T1_miss_count_aver, T2_miss_count_aver))

    # determine whether schedulable or not
    T1_Dead_satis_prob = 1 - (T1_miss_count_aver/T1_tx_count)
    T2_Dead_satis_prob = 1 - (T2_miss_count_aver/T2_tx_count)
    print("T1_Dead_satis_prob:%s     T2_Dead_satis_prob:%s" %(T1_Dead_satis_prob, T2_Dead_satis_prob))
    if T1_Dead_satis_prob < 0.99 or T2_Dead_satis_prob < 0.99:
        Unschedulable_count = Unschedulable_count + 1
print("Unschedulable_count of %s: %s"%(Utilization, Unschedulable_count))
