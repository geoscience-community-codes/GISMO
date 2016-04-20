function sst = sort_sst(sst)
%SORT_SST: Sort SST (Event Start/Stop Times) based on start times
%
%USAGE: sst = sort_sst(sst)
%
%INPUTS: sst --> nx2 Start/Stop Time (datenum) array (unsorted)  
%
%OUTPUTS: N --> nx2 Start/Stop Time (datenum) array (sorted)
%
% See also ADD_SST, CHK_T, COMPARE_SST, DELETE_SST, EXTRACT_SST, IS_SST,  
%          ISTEQUAL, MERGE_SST, SEARCH_SST, SORT_SST, NAN2SST, SSD2SST,  
%          SST2NAN, SST2SSD, SST2VAL, SST2WFA, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

[S N] = sort(sst(:,1));
sst = [S; sst(N,2)];