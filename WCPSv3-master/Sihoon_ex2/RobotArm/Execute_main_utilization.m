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
Protocol_butt = 0; % 0 if proposed protocol, 1 if WirelessHART

file_name0 = 'MaxUtil_ours_v3.mat';
file_name1 = 'MaxUtil_WH_v3.mat';
field_name_P1 = 'MAE_P1';  
field_name_P2 = 'MAE_P2';  
MAE_P1 = [];
MAE_P2 = [];

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
        save(save_file_name, field_name_P1, field_name_P2);
    else
        save(save_file_name, field_name_P1, field_name_P2);
    end
end


%%% Run TOSSIM & Simulink %%%
if RunSimul_butt ~= 0
    num_simulation = 50;
    t = tcpip('127.0.0.1', 10030);  % Which signal to TOSSIM_interface.py
    fopen(t);
    for i=1:num_simulation
        pause (1);
        fwrite(t,'Open TOSSIM');
        pause (1);
        run('robot_arm_main_utilization.m')
        pause (1);
    end
    fwrite(t,'Close TOSSIM');
    pause (1);
    fclose(t);
end

