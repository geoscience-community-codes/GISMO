function c = strip(c)
   
   % c = STRIP(c)
   % This function "deletes" the correlation matrix from the
   % correlation object. This frees up considerable memory. It also removes
   % the necessity to keep these CPU-intensive fields updated. For example,
   % when the stack function adds a new trace, it automatically calls XCORR to
   % add correlation info for the new trace. If the CORR matrix is empty, then
   % it skips this potentially time consumming step. Realistically, once the
   % link field as been filled (via the LINKAGE function), the correlation
   % matrix is often no longer needed.
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   c.corrmatrix = [];
end
