function [resultz] = ps_aggregation (call_count, rssi, clock)
global simul_time Dis_instant_P1
resultz = zeros(call_count, 8);

finish_flag = 0;    % signal to TOSSIM with finish instant
if clock == simul_time
    finish_flag = 1;
end
dist_inst_P1 = Dis_instant_P1;

for i_pa = 1 : call_count
    [result status]=python('tossim-event-client_broadcast_interval.py', num2str(rssi), num2str(finish_flag), num2str(dist_inst_P1));
    resultz(i_pa, :) = str2num(result);
end