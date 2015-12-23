function c = sign(c,varargin);
   
   % SIGN convert traces to the sign of their data (+1, 0, -1)
   %
   % C = SIGN(C) For each element of each trace, SIGN returns 1 if the element
   %     is greater than zero, 0 if it equals zero and -1 if it is
   %     less than zero.
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   c.traces = sign(c.traces);
end