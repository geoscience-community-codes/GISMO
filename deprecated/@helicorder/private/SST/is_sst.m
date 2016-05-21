function bool = is_sst(sst)

%IS_SST: Determine if array 'sst' is in proper SST format (Nx2 numeric)
%
%USAGE: bool = is_sst(sst)
%
%INPUTS: sst - Event Start/Stop Times [Nx2 array of numeric time values]
%
%OUTPUTS: bool - 1 or 0
%
% See also ADD_SST, CHK_T, COMPARE_SST, DELETE_SST, EXTRACT_SST, IS_SST,  
%          ISTEQUAL, MERGE_SST, SEARCH_SST, SORT_SST, NAN2SST, SSD2SST,  
%          SST2NAN, SST2SSD, SST2VAL, SST2WFA, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

bool = 1;
if iscell(sst)
   for m = 1:numel(sst)
      if ~isnumeric(sst{m})||size(sst{m},2)~=2;
         bool =  0; 
      end
   end
elseif ~isnumeric(sst)||size(sst,2)~=2;
   bool =  0; 
end
