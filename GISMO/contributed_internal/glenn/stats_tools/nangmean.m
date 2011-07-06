function nang=nangmean(x)
i=0;totallog=0;
for c=1:length(x)
   if ~isnan(x(c))
      totallog=totallog+log(x(c));
      i=i+1;
   end
end
if i~=0
   nanavlog=totallog/i;
   nang=exp(nanavlog);
else
   nang=NaN;
end