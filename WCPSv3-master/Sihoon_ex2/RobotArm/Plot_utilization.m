%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot broadcast_interval results generated from N simulations
% ('Execute_main_broadcast_interval.m' file)
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
clc;


%% Log file
file_name_Ours_SameUtil = 'SameUtil_ours_v3.mat';     % store results for a simulation
file_name_WH_SameUtil = 'SameUtil_WH_v3.mat';
file_name_Ours_MaxUtil = 'MaxUtil_ours_v3.mat';
file_name_WH_MaxUtil = 'MaxUtil_WH_v3.mat';

field_name_P1 = 'MAE_P1';  
field_name_P2 = 'MAE_P2';  

Ours_Log_SameUtil_P1 = [];
Ours_Log_SameUtil_P2 = [];
WH_Log_SameUtil_P1 = [];
WH_Log_SameUtil_P2 = [];
Ours_Log_MaxUtil_P1 = [];
Ours_Log_MaxUtil_P2 = [];
WH_Log_MaxUtil_P1 = [];
WH_Log_MaxUtil_P2 = [];


%% Get log data
Ours_Log_SameUtil_P1 = struct2array(load(file_name_Ours_SameUtil, field_name_P1));
Ours_Log_SameUtil_P2 = struct2array(load(file_name_Ours_SameUtil, field_name_P2));
WH_Log_SameUtil_P1 = struct2array(load(file_name_WH_SameUtil, field_name_P1));
WH_Log_SameUtil_P2 = struct2array(load(file_name_WH_SameUtil, field_name_P2));

Ours_Log_MaxUtil_P1 = struct2array(load(file_name_Ours_MaxUtil, field_name_P1));
Ours_Log_MaxUtil_P2 = struct2array(load(file_name_Ours_MaxUtil, field_name_P2));
WH_Log_MaxUtil_P1 = struct2array(load(file_name_WH_MaxUtil, field_name_P1));
WH_Log_MaxUtil_P2 = struct2array(load(file_name_WH_MaxUtil, field_name_P2));



%% filter the unstable (divergence) results : eliminate the greatest 5 values

[A, A_idx, Ours_Log_SameUtil_P1] = maxk2(Ours_Log_SameUtil_P1, 5);
[A, A_idx, Ours_Log_SameUtil_P2] = maxk2(Ours_Log_SameUtil_P2, 5);
[A, A_idx, WH_Log_SameUtil_P1] = maxk2(WH_Log_SameUtil_P1, 5);
[A, A_idx, WH_Log_SameUtil_P2] = maxk2(WH_Log_SameUtil_P2, 5);

[A, A_idx, Ours_Log_MaxUtil_P1] = maxk2(Ours_Log_MaxUtil_P1, 5);
[A, A_idx, Ours_Log_MaxUtil_P2] = maxk2(Ours_Log_MaxUtil_P2, 5);
[A, A_idx, WH_Log_MaxUtil_P1] = maxk2(WH_Log_MaxUtil_P1, 5);
[A, A_idx, WH_Log_MaxUtil_P2] = maxk2(WH_Log_MaxUtil_P2, 5);

%% Plot with CDF graph
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
boxplot([Ours_Log_SameUtil_P1' Ours_Log_SameUtil_P2' WH_Log_SameUtil_P1' WH_Log_SameUtil_P2']);
set(gca,'TickLabelInterpreter', 'tex');
set(gca,'xticklabel',{'AH:P_{hi}', 'AH:P_{lo}', 'WH:P_{hi}', 'WH:P_{lo}'});
ylabel('MAE');
set(gca, 'fontweight', 'bold', 'fontsize', 11);
   
%ylim([0 2]);


f2 = figure;
set(f2, 'renderer', 'painters');
set(f2, 'units', 'inches');
set(f2, 'position', [3 6 fig_width fig_height]);
set(f2, 'PaperUnits', 'inches');
set(f2, 'PaperSize', [fig_width fig_height]);
set(f2, 'PaperPositionMode', 'manual');
set(f2, 'PaperPosition', [0 0 fig_width fig_height]);

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
boxplot([Ours_Log_MaxUtil_P1' Ours_Log_MaxUtil_P2' WH_Log_MaxUtil_P1' WH_Log_MaxUtil_P2']);
set(gca,'TickLabelInterpreter', 'tex');
set(gca,'xticklabel',{'AH:P_{hi}', 'AH:P_{lo}', 'WH:P_{hi}', 'WH:P_{lo}'});
ylabel('MAE');
set(gca, 'fontweight', 'bold', 'fontsize', 11);

    
% Print increasing rates against SameUtil/MaxUtil
mean_Ours_SameUtil_P1 = mean(Ours_Log_SameUtil_P1)
mean_Ours_MaxUtil_P1 = mean(Ours_Log_MaxUtil_P1);
mean_Ours_SameUtil_P2 = mean(Ours_Log_SameUtil_P2);
mean_Ours_MaxUtil_P2 = mean(Ours_Log_MaxUtil_P2);
mean_WH_SameUtil_P1 = mean(WH_Log_SameUtil_P1)
mean_WH_MaxUtil_P1 = mean(WH_Log_MaxUtil_P1);
mean_WH_SameUtil_P2 = mean(WH_Log_SameUtil_P2);
mean_WH_MaxUtil_P2 = mean(WH_Log_MaxUtil_P2);

Ours_P1_incrs_rate = mean_Ours_SameUtil_P1/mean_Ours_MaxUtil_P1
Ours_P2_incrs_rate = mean_Ours_SameUtil_P2/mean_Ours_MaxUtil_P2
WH_P1_incrs_rate = mean_WH_SameUtil_P1/mean_WH_MaxUtil_P1
WH_P2_incrs_rate = mean_WH_SameUtil_P2/mean_WH_MaxUtil_P2

Ratio_OursP1_over_WHP1_on_SameUtil = mean_WH_SameUtil_P1/mean_Ours_SameUtil_P1;
Ratio_OursP2_over_WHP2_on_SameUtil = mean_WH_SameUtil_P2/mean_Ours_SameUtil_P2;
Ratio_OursP1_over_WHP1_on_MaxUtil = mean_WH_MaxUtil_P1/mean_Ours_MaxUtil_P1;
Ratio_OursP2_over_WHP2_on_MaxUtil = mean_WH_MaxUtil_P2/mean_Ours_MaxUtil_P2;

function [B BIndex RestVector]= maxk2(A, k)
B = 0;
RestVector = A;
sumIndex = 1;
for i=1:k
  MaxA = max(A);
  I = A == MaxA;
  sumI = sum(I); %To find number of Max elements (repeated) 
  B(sumIndex: sumIndex+sumI-1) = MaxA; % to same max elements in B
  BIndex(sumIndex: sumIndex+sumI-1) = find(A == MaxA); 
  sumIndex = sumIndex + sumI; 
  A(I) = min(A); % exchange the max elements by a smallest value  
end
RestVector(BIndex) = [];  % remove largest values
end