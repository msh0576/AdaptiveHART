clear all;
clc;

sim_time = 20;
delta = 0.001;

% Disturbance
Dis_instant = 10;
Dis_interval = 3;
Dis_size = 5;

%% Initilize
m = 0.111;
R = 0.015;
g = -9.8;
J = 9.99e-6;

H = -m*g/(J/(R^2)+m);

A = [0 1 0 0
     0 0 H 0
     0 0 0 1
     0 0 0 0];
B = [0;0;0;1];
C = [1 0 0 0];
D = [0];

A_ = [0 1 0 0
     0 0 H 0
     0 0 0 1
     0 0 0 0];
B_ = [0;0;0;1];
C_ = [1 0 0 0];
D_ = [0];

poles = [-0.5+2i; -0.5-2i; -6; -13];

K = place(A,B,poles);

Nbar = rscale(A,B,C,D,K);





%% Simulink
sim('BallBeam_simul');


%% Plot


%%% Plot %%%
% Data Setting
Ideal_output_signal_buffer = [];
Wireless_output_signal_buffer = [];
Wireless_output_signal_WHART_buffer = [];

%Ideal_output_signal = load('Ideal_Output_log.mat');
Ideal_output_signal = load('Wireless_Output_log_D-MAC1.mat');
Ideal_output_signal_buffer = [Ideal_output_signal_buffer Ideal_output_signal];
Ideal_each_field = getfield(Ideal_output_signal_buffer, {1});
Ideal_arr = struct2array(Ideal_each_field);
Ideal_time_ = Ideal_arr.Time;
Ideal_output_ = Ideal_arr.Data;    
Ideal_position = Ideal_output_(:,1); % position

Wireless_output_signal = load('Wireless_Output_log_D-MAC.mat');
Wireless_output_signal_buffer = [Wireless_output_signal_buffer Wireless_output_signal];
Wireless_each_field = getfield(Wireless_output_signal_buffer, {1});
Wireless_arr = struct2array(Wireless_each_field);
Wireless_time_ = Wireless_arr.Time;
Wireless_output_ = Wireless_arr.Data;
Wireless_position = Wireless_output_(:,1); %position
%{
Wireless_output_signal_WHART = load('Wireless_Output_log_WHART.mat');
Wireless_output_signal_WHART_buffer = [Wireless_output_signal_WHART_buffer Wireless_output_signal_WHART];
Wireless_each_field_WHART = getfield(Wireless_output_signal_WHART_buffer, {1});
Wireless_arr_WHART = struct2array(Wireless_each_field_WHART);
Wireless_time_WHART = Wireless_arr_WHART.Time;
Wireless_output_WHART = Wireless_arr_WHART.Data;
%}
% Graph Setting
fig_width     = 4; % inch
fig_height    = 3;
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


plot(Ideal_time_, Ideal_position, 'k --')
hold on;
plot(Wireless_time_, Wireless_position, 'r-')

%plot(Wireless_time_WHART, Wireless_output_WHART, 'b-')

%ylim([0,1.5]);
legend('Ideal','D-MAC');
xlabel('Time(s)');
ylabel('Output signal y(t)');
grid on;

%%% accumulated Error %%%
%AE = sum(abs(Ideal_output_ - Wireless_output_))