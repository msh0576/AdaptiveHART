%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set initial physical system model, and Task periods/Disturbance instant
%
% Save utilization results both on same and maximum resources for a one
% simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%clear all;
%clc;

global delta simul_time Task_periods

delta = 0.001;       % Simulink operate every 1ms
delta_t = 10;
simul_time = 20;    % Simulation time
Task_periods = [11; 11];

%% Button %%
Plot_butt = 0;
Sim_butt = 1;
Protocol_butt = 0; % 0 if proposed protocol, 1 if WirelessHART

%% Save File %%
file_name0 = 'MaxUtil_ours_v3.mat';
file_name1 = 'MaxUtil_WH_v3.mat';
field_name_P1 = 'MAE_P1';  
field_name_P2 = 'MAE_P2';  

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
T_ = 15;
A_=[0 1/T_; 0 0];
B_=[0;1];
C_=[1 0];
D_=0;

pole_ = [-3.02 -1.08];
%pole_ = [-3.82 -1.48];
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
Dis_instant_P1 = 10;   %P1
Dis_interval_P1 = 5;
Dis_size_P1 = 10;

Dis_instant_P2 = 10;   %P2
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
    sim('robot_arm_simul_utilization');
end

% Log Data %
% Ideal: P1
Ideal_P1_output = load('Optimal_P1_output_util.mat');
Ideal_P1_output = struct2array(Ideal_P1_output);
Ideal_P1_time = Ideal_P1_output.Time;
Ideal_P1_state = Ideal_P1_output.Data;

% Ideal: P2
Ideal_P2_output = load('Optimal_P2_output_util.mat');
Ideal_P2_output = struct2array(Ideal_P2_output);
Ideal_P2_time = Ideal_P2_output.Time;
Ideal_P2_state = Ideal_P2_output.Data;

if Protocol_butt == 0
    % DMAC: P1
    Ours_P1_output = load('Ours_P1_output_util.mat');
    Ours_P1_output = struct2array(Ours_P1_output);
    Ours_P1_time = Ours_P1_output.Time;
    Ours_P1_state = Ours_P1_output.Data;
    % DMAC: P2
    Ours_P2_output = load('Ours_P2_output_util.mat');
    Ours_P2_output = struct2array(Ours_P2_output);
    Ours_P2_time = Ours_P2_output.Time;
    Ours_P2_state = Ours_P2_output.Data;
else
    % WH: P1
    Ours_P1_output = load('WH_P1_output_util.mat');
    Ours_P1_output = struct2array(Ours_P1_output);
    Ours_P1_time = Ours_P1_output.Time;
    Ours_P1_state = Ours_P1_output.Data;
    % WH: P2
    Ours_P2_output = load('WH_P2_output_util.mat');
    Ours_P2_output = struct2array(Ours_P2_output);
    Ours_P2_time = Ours_P2_output.Time;
    Ours_P2_state = Ours_P2_output.Data;
end



%% Save Results %%

% accumulated Error
% For P1
MAE_P1 = mean(abs(Ideal_P1_state - Ours_P1_state));

% For P2
MAE_P2 = mean(abs(Ideal_P2_state - Ours_P2_state));


% Append the results
Load_result = load(save_file_name);
Load_field_P1 = getfield(Load_result, field_name_P1);
Load_field_P2 = getfield(Load_result, field_name_P2);

MAE_P1 = [Load_field_P1 MAE_P1]
MAE_P2 = [Load_field_P2 MAE_P2]

save(save_file_name, field_name_P1, field_name_P2);

