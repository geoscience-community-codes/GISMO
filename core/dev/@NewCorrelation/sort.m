function c = sort(c)
   
   % C = SORT(C) Sorts traces from oldest to youngest.
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   [~,I] = sort(c.trig);
   c = subset(c,I);
end
