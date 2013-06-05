function bool = istequal(t1,t2)

%ISTEQUAL: Compare 2 Matlab time values for equality
%
%USAGE: bool = istequal(t1,t2)
%
%INPUTS: t1,t2 - Matlab formatted date numbers
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


t1 = round(t1*24*60*60*1000); % Units: seconds/1000
t2 = round(t2*24*60*60*1000); % Units: seconds/1000
bool = isequal(t1,t2);