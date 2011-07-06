function m=nanpercentile(x,fraction)
x=sort(x);
c=length(x);
while isnan(x(c)) 
   c=c-1;
   if c<1
      m=NaN;
      return;
   end
end
mi=round(c*fraction);
m=x(mi);
return;