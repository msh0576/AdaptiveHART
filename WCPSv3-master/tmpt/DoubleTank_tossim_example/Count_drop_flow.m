load 'trace.mat'

Count_drop = 0;

for n= 2:1:1000
    if(trace1(2,n) == 0)
        Count_drop = Count_drop + 1;
    end
end

Count_drop