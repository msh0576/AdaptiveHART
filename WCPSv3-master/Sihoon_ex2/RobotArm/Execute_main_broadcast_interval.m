%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   run TOSSIM_interface.py on a terminal
%   and then run this file
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
clc;

% Comments button: 1 for execution, 0 for skip
Init_butt = 1;
RunSimul_butt = 1;
PlotResult_butt = 0;
Protocol_butt = 1; % 0 if proposed protocol, 1 if WirelessHART

% save file
file_name0 = 'Simul_results_Ours_broadcast_interval_5hop_300hp_v2.mat';     % store results for a simulation
file_name1 = 'Simul_results_WH_broadcast_interval_5hop_300hp_v3.mat';
field_name_P1 = 'Log_broad_interv_P1';  
Log_broad_interv_P1 = [];

if Protocol_butt == 0
    save_file_name = file_name0;
else
    save_file_name = file_name1;
end


%%% Delete already existing .mat %%%
% It should be run once at first simulation
if Init_butt ~= 0
    if exist(save_file_name)
        delete(save_file_name); 
        save(save_file_name, field_name_P1);
    else
        save(save_file_name, field_name_P1);
    end
end


%%% Run TOSSIM & Simulink %%%
num_simulation = 100;
if RunSimul_butt ~= 0
    t = tcpip('127.0.0.1', 10030);  % Which signal to TOSSIM_interface.py
    fopen(t);
    for i=1:num_simulation
        pause (1);
        fwrite(t,'Open TOSSIM');
        pause (1);
        run('robot_arm_main_broadcast_interval.m')
        pause (1);
    end
    fwrite(t,'Close TOSSIM');
    pause (1);
    fclose(t);
end
