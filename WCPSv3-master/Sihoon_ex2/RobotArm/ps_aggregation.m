function [resultz] = ps_aggregation (call_count, rssi, clock)
global simul_time
resultz = zeros(call_count, 8);

finish_flag = 0;    % signal to TOSSIM with finish instant
if clock == simul_time
    finish_flag = 1;
end

for i_pa = 1 : call_count
    [result status]=python('tossim-event-client.py', num2str(rssi), num2str(finish_flag));
    %[result status]=python('test_tossim.py', num2str(rssi));
    %[result status]=python('example_socket_client.py', num2str(rssi));
    resultz(i_pa, :) = str2num(result);
end