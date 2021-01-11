
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Present system outputs, actuation interval, PDR, and network parameters
% (task period and maxReTx)
%
% Run the TOSSIM file "tossim-evet-server_adaptability.py" 
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear all;
clc;

global delta simul_time Task_periods Dis_instant_P1 Dis_finish_P1

delta = 0.001;       % Simulink operate every 1ms
delta_t = 10;
simul_time = 60;    % Simulation time
Task_periods = [0.30; 0.30];


%% Button %%
Plot_butt = 1;
Sim_butt = 0;


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
Dis_instant_P1 = 20;   %P1
Dis_interval_P1 = 10;
Dis_finish_P1 = Dis_instant_P1 + Dis_interval_P1;
Dis_size_P1 = 20;

Dis_instant_P2 = 100;   %P2
Dis_interval_P2 = 5;
Dis_size_P2 = 10;

O = obsv(A,C);
if rank(A) == rank(C)
    disp('System is observable')
else
    disp('System is not observable')
end



%% Run Simulink %%
Ideal_output_signal_buffer = [];
Wireless_output_signal_buffer = [];
Wireless_output_signal_WHART_buffer = [];
if Sim_butt == 1
    sim('robot_arm_simul_adaptability');
end

%% Get Log data %%

% Log Data %
% Ideal: P1
Ideal_P1_output = load('Optimal_P1_output.mat');
Ideal_P1_output = struct2array(Ideal_P1_output);
Ideal_P1_time = Ideal_P1_output.Time;
Ideal_P1_state = Ideal_P1_output.Data;

% Ideal: P2
Ideal_P2_output = load('Optimal_P2_output.mat');
Ideal_P2_output = struct2array(Ideal_P2_output);
Ideal_P2_time = Ideal_P2_output.Time;
Ideal_P2_state = Ideal_P2_output.Data;

% DMAC: P1 output
DMAC_P1_output = load('Ours_P1_output.mat');
DMAC_P1_output = struct2array(DMAC_P1_output);
DMAC_P1_time = DMAC_P1_output.Time;
DMAC_P1_state = DMAC_P1_output.Data;
% DMAC: P2 output
DMAC_P2_output = load('Ours_P2_output.mat');
DMAC_P2_output = struct2array(DMAC_P2_output);
DMAC_P2_time = DMAC_P2_output.Time;
DMAC_P2_state = DMAC_P2_output.Data;


P1_actu_interval = load('P1_actu_interval.mat');
P1_actu_interval = struct2array(P1_actu_interval);

T1_period = load('Task1_period.mat');
T1_period = struct2array(T1_period);

T1_noise = load('Task1_noise.mat');
T1_noise = struct2array(T1_noise);

T1_maxTx = load('Task1_maxTx.mat');
T1_maxTx = struct2array(T1_maxTx);

P1_PDR = load('P1_PDR.mat');
P1_PDR = struct2array(P1_PDR);

P1_dist = load('P1_dist.mat');
P1_dist = struct2array(P1_dist);


%% Plot %%
if Plot_butt == 1
    fig_width     = 9; % inch
    fig_height    = 8;
    margin_vert_u = 0.3;
    margin_vert_d = 0.45;
    margin_horz_l = 0.55;
    margin_horz_r = 0.25;

    fontname = 'times new roman';
    set(0, 'defaultaxesfontname', fontname);
    set(0, 'defaulttextfontname', fontname);

    fontsize = 9; %pt
    set(0, 'defaultaxesfontsize', fontsize);
    set(0, 'defaulttextfontsize', fontsize);
    set(0, 'fixedwidthfontname', 'times');

    hFig = figure;
    set(hFig, 'renderer', 'painters');
    set(hFig, 'units', 'inches');
    set(hFig, 'position', [3 6 fig_width fig_height]);
    set(hFig, 'PaperUnits', 'inches');
    set(hFig, 'PaperSize', [fig_width fig_height]);
    set(hFig, 'PaperPositionMode', 'manual');
    set(hFig, 'PaperPosition', [0 0 fig_width fig_height]);

    hAxe = axes;

    set(hAxe, 'activepositionproperty', 'outerposition');
    set(hAxe, 'units', 'inches');
    ax_pos = get(hAxe, 'position');
    ax_pos(4) = fig_height-margin_vert_u-margin_vert_d;
    ax_pos(2) = fig_height-(margin_vert_u+ax_pos(4));
    ax_pos(3) = fig_width-margin_horz_l-margin_horz_r;
    ax_pos(1) = margin_horz_l;
    set(hAxe, 'position', ax_pos);

    box(hAxe,'on');

    hold on;

    
    
    subplot(7,1,1);
    plot(Ideal_P1_time, Ideal_P1_state, 'k --', 'LineWidth', 2)
    hold on;
    plot(DMAC_P1_time, DMAC_P1_state, 'r-', 'LineWidth', 2)
    ylim([-3, 5]);
    legend('Optimal','ERA');
    ylabel({'(a)', 'Output', 'y(t)'}, 'FontWeight', 'bold');
    grid on;
    set(gca,'fontweight', 'bold', 'fontsize', 11);

    subplot(7,1,2);
    plot(P1_dist.Time, P1_dist.Data, 'b-', 'LineWidth', 2);
    grid on;
    ylabel({'(b)', 'Physical', 'disturbance'}, 'FontWeight', 'bold');
    ylim([-30 30]);
    set(gca,'fontweight', 'bold', 'fontsize', 11);
    
    subplot(7,1,3);
    plot(T1_noise.Time, T1_noise.Data, 'b-', 'LineWidth', 2);
    grid on;
    ylabel({'(c)', 'Wireless','noise'}, 'FontWeight', 'bold');
    ylim([-90 -60]);
    set(gca,'fontweight', 'bold', 'fontsize', 11);
    
    subplot(7,1,4);
    plot(T1_period.Time, T1_period.Data, 'g-', 'LineWidth', 2);
    grid on;
    ylim([0 0.4]);
    ylabel({'(d)', 'Task1', 'period'}, 'FontWeight', 'bold');
    set(gca,'fontweight', 'bold', 'fontsize', 11);
    
    subplot(7,1,5);
    plot(T1_maxTx.Time, T1_maxTx.Data, 'g-', 'LineWidth', 2);
    grid on;
    ylabel({'(e)', 'Task1','max #Tx',' '}, 'FontWeight', 'bold');
    ylim([0.5 8.5]);
    set(gca,'fontweight', 'bold', 'fontsize', 11);

    subplot(7,1,6);
    plot(P1_actu_interval.Time, P1_actu_interval.Data, 'r-', 'LineWidth', 2);
    grid on;
    ylim([0 1]);
    ylabel({'(f)', 'Actuation','interval'}, 'FontWeight', 'bold');
    set(gca,'fontweight', 'bold', 'fontsize', 11);
    
    subplot(7,1,7);
    plot(P1_PDR.Time, P1_PDR.Data, 'r-', 'LineWidth', 2);
    grid on;
    ylabel({'(g)', 'Actuation','PDR'}, 'FontWeight', 'bold');
    ylim([0 1.1]);
    
    xlabel('Time(s)', 'FontWeight', 'bold');
    set(gca,'fontweight', 'bold', 'fontsize', 11);
end
