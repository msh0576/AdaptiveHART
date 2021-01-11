function [resultz] = ps_aggregation (call_count, rssi)

resultz = zeros(call_count, 8);

for i_pa = 1 : call_count
    [result status]=python('tossim-event-client.py', num2str(rssi))
    %[result status]=python('test_tossim.py', num2str(rssi));
    %[result status]=python('example_socket_client.py', num2str(rssi));
    resultz(i_pa, :) = str2num(result);
end