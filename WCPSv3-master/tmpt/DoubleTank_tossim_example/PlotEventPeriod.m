load event-manual.mat

Etime = EventP(1,:);
Evalue = EventP(2,:);
count=1;
diff=[]
% s=-0.1500

for n=Etime(1,2:end)
    if (Evalue(1,n)>-0.001)
        diff(1,count)=Etime(1,n);
        count=count+1;
    end
    
%     if (s~=0)
%         count=count+1;
%     end
end    

