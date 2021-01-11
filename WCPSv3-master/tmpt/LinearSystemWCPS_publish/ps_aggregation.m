function [resultz] = ps_aggregation (call_count, rssi, Event_count1 , Event_count2)

resultz = zeros(call_count, 8);

for i_pa = 1 : call_count
    %[result status]=python('tossim-event-client.py', num2str(rssi), num2str(Event_count1));
    [result status]=python('tossim-event-client.py',num2str(Event_count1), num2str(Event_count2));
    resultz(i_pa, :) = str2num(result);
end