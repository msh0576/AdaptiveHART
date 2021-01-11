load 'EventCount.mat'

totaleventcount=0;

for n= 2:1:6000
   if ((EventC(2,n)-EventC(2,n-1))~=0)
       totaleventcount = totaleventcount+1;
   end
end
totaleventcount