function sst = merge_sst(sst,varargin)

%MERGE_SST: Take array to Start/Stop Time (Nx2) and merge together SST
%           elements that overlap each other. Argument can be passed to
%  merge elements separated by a minimum spacing (varargin) in seconds
%
%USAGE: sst = merge_sst(sst) --> Merges sst that overlap
%       sst = merge_sst(sst,N) --> Merges sst that overlap, or are
%                                  separated by N seconds or less
%
%INPUTS: sst (to be merged)
%
%OUTPUTS: sst (merged)
%
% See also ADD_SST, CHK_T, COMPARE_SST, DELETE_SST, EXTRACT_SST, IS_SST,  
%          ISTEQUAL, MERGE_SST, SEARCH_SST, SORT_SST, NAN2SST, SSD2SST,  
%          SST2NAN, SST2SSD, SST2VAL, SST2WFA, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

done = 0;
n = 1;
if nargin == 2
   gap = varargin{1}; % merge sst separated by this many seconds or less
   gap = gap/24/60/60;
else
   gap = 0;
end

while done == 0
   if n<length(sst)
      if sst(n,2) >= sst(n+1,1)-gap
         if sst(n,2) < sst(n+1,2)
            sst(n,:) = [sst(n,1) sst(n+1,2)];
         end
         sst(n+1,:) = [];
      else
         n = n + 1;
      end
   else
      done = 1;
   end
end