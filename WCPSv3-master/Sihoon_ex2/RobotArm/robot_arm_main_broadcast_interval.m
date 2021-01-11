
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deliver the diturbance recognition instant (dist_inst) to TOSSIM
% 
% Measure the first changed actuation interval instant of plants 
% 
% Refer to the interval from change-before instant to the first changed
% actuation interval instant as application interval
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% clear all;
% clc;

global delta simul_time Task_periods Dis_instant_P1 broad_interv_P1

delta = 0.001;       % Simulink operate every 1ms
delta_t = 10;
simul_time = 6;    % Simulation time
Task_periods = [0.30; 0.30];


%% Button %%
Plot_butt = 0;
Sim_butt = 1;
Protocol_butt = 1; % 0 if proposed protocol, 1 if WirelessHART

%% Save File %%
file_name0 = 'Simul_results_Ours_broadcast_interval_5hop_300hp_v2.mat';     % store results for a simulation
file_name1 = 'Simul_results_WH_broadcast_interval_5hop_300hp_v3.mat';
field_name_P1 = 'Log_broad_interv_P1';  
log_name_P1 = 'broad_interv_P1.mat';


if Protocol_butt == 0
    save_file_name = file_name0;
else
    save_file_name = file_name1;
end

%% Initialize %%

% Plant 1
T = 6;
A=[0 1/T; 0 0];
B=[0;1];
C=[1 0];
D=0;

% Compute K and DC gain
pole = [-4.02 -1.58];
%pole = [-5 -2];
%pole = [-8 -3];
K = place(A,B,pole);
% pole check
% eig(A-B*K)
sys = ss(A-B*K, B, C, D);
DC_gain = dcgain(sys);
%K = [14.4 3.8];
%obpoles = [-1.6 -6];
obpoles = [-20 -8];
l = place(A',C',obpoles);
L = l';

% Plant 2
T_ = 12;
A_=[0 1/T_; 0 0];
B_=[0;1];
C_=[1 0];
D_=0;

pole_ = [-3.02 -1.08];
%pole_ = [-8 -3];
K_ = place(A_,B_,pole_);
sys_ = ss(A_-B_*K_, B_, C_, D_);
DC_gain_ = dcgain(sys_);
%K = [14.4 3.8];
%obpoles_ = [-1.6 -6];
obpoles_ = [-20 -8];
l_ = place(A_', C_', obpoles_);
L_ = l_';

% Reference
ref_P1 = 1;
ref_P1 = ref_P1/DC_gain;
ref_P2 = 1;
ref_P2 = ref_P2/DC_gain_;

% Disturbance
% generate random disturbance instant
Dis_instant_P1 = randi([1 simul_time-1])   %P1
Dis_interval_P1 = simul_time;
Dis_size_P1 = 10;

Dis_instant_P2 = 100;   %P2
Dis_interval_P2 = 5;
Dis_size_P2 = 10;

O = obsv(A,C);
if rank(A) == rank(C)
    disp('System is observable')
else
    disp('System is not observable')
end



%% Simulink %%
Ideal_output_signal_buffer = [];
Wireless_output_signal_buffer = [];
Wireless_output_signal_WHART_buffer = [];
if Sim_butt == 1
    sim('robot_arm_simul_broadcast_interval');
end

% Log Data %
% Ideal: P1
Ideal_P1_output = load('Ideal_Output_log_P1.mat');
Ideal_P1_output = struct2array(Ideal_P1_output);
Ideal_P1_time = Ideal_P1_output.Time;
Ideal_P1_state = Ideal_P1_output.Data;

% Ideal: P2
Ideal_P2_output = load('Ideal_Output_log_P2.mat');
Ideal_P2_output = struct2array(Ideal_P2_output);
Ideal_P2_time = Ideal_P2_output.Time;
Ideal_P2_state = Ideal_P2_output.Data;

% DMAC: P1
DMAC_P1_output = load('Wireless_Output_log_DMAC_P1.mat');
DMAC_P1_output = struct2array(DMAC_P1_output);
DMAC_P1_time = DMAC_P1_output.Time;
DMAC_P1_state = DMAC_P1_output.Data;
% DMAC: P2
DMAC_P2_output = load('Wireless_Output_log_DMAC_P2.mat');
DMAC_P2_output = struct2array(DMAC_P2_output);
DMAC_P2_time = DMAC_P2_output.Time;
DMAC_P2_state = DMAC_P2_output.Data;


%% Save result %%
tmp_broad_interv_P1 = load(log_name_P1);
tmp_broad_interv_P1 = struct2array(tmp_broad_interv_P1);
last_idx = length(tmp_broad_interv_P1.Data);
curr_broad_interv_P1 = tmp_broad_interv_P1.Data(last_idx);

% Append the results
Load_result = load(save_file_name);
Load_broad_interv_P1 = getfield(Load_result, field_name_P1);

Log_broad_interv_P1 = [Load_broad_interv_P1 curr_broad_interv_P1]

save(save_file_name, field_name_P1);

% Final results are presented in the file "Plot_broadcast_interval.m"
