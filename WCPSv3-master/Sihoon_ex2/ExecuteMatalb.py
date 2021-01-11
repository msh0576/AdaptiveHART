#!/usr/bin/env python
import commands
import sys
import os
import matlab.engine
from scipy import io


def gcd(a,b):
    """Compute the greatest common divisor of a and b"""
    while b > 0:
        a, b = b, a % b
    return a

def lcm(a, b):
    """Compute the lowest common multiple of a and b"""
    return a * b / gcd(a, b)



print("I am in python")

matlab_file_path = "/home/sihoon/WCPSv3-master/Sihoon_ex2/RobotArm/"

tossim_file_path = "/home/sihoon/WCPSv3-master/Sihoon_ex2/Log_file/"


### Task Period Setting ###
# it should be harmonic of all task periods
Each_task_T = [25, 25]

### Initilization ###
# Index
NODEID = 0
FLOWID = 1
RCV_COUNT = 2
SUPERFRAME_LEN = lcm(Each_task_T[0], Each_task_T[1])     # check slot0 ~ slot19


### Execute WCPS simulator ###
Simul_time = 2
N_simul_results = []

save_file_name = 'Simul_results.mat'
field_name = 'AE'
for N in range(Simul_time):
    ### Tossim ###
    exe_file_name = "Test"+str(N)+".txt"
    fail, output = commands.getstatusoutput("python tossim-event-server.py" +" "+str(Each_task_T[0])+" "+str(Each_task_T[1]) + " >>"+str(tossim_file_path)+str(exe_file_name))
    #fail, output = commands.getstatusoutput("python tossim-event-server.py" +" "+str(Each_task_T[0])+" "+str(Each_task_T[1]) + " >>"+str(file_path)+str(exe_file_name))
    faile_check(fail)

    ### Matlab ###
    eng = matlab.engine.start_matlab()
    eng.cd(matlab_file_path)
    eng.robot_arm_main(nargout=0)
    eng.quit()
    # Bring matlab results
    mat_file = io.loadmat(matlab_file_path+save_file_name)
    print(mat_file['AE'][0][0])
    print(type(mat_file['AE'][0][0]))
    N_simul_results.append(mat_file['AE'][0][0])

print(N_simul_results)
