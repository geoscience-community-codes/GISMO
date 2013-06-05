function sub_sst = extract_sst(sst,t1,t2,edge_mode)

%EXTRACT_SST: Extract event SST (Start/Stop Times) between t1 and t2
%
%USAGE: sub_sst = extract_sst(sst,t1,t2,edge_mode)
%
%INPUTS: sst - Event Start/Stop Times [Nx2 array of numeric time values]
%        t1  - time value, extract all events in sst between t1 (start) 
%              and t2 (end)
%        t2  - see 't1'
%        edge_mode  - If t1 or t2 falls between an event start time and 
%                stop time in sst edge_mode determines if the event is 
%                deleted, retained, or partially deleted at time t1 or t2.
%           'delete' - whole event is removed from array sub_sst
%           'keep'   - whole event is retained in array sub_sst
%           'part'   - event in sub_sst is split - i.e. deleted 
%                       before t1 or after t2
%
%OUTPUTS: sub_sst - Subset of origianl sst (Event Start/Stop Times) 
%                   [Nx2 array of numeric time values]
%
% See also ADD_SST, CHK_T, COMPARE_SST, DELETE_SST, EXTRACT_SST, IS_SST,  
%          ISTEQUAL, MERGE_SST, SEARCH_SST, SORT_SST, NAN2SST, SSD2SST,  
%          SST2NAN, SST2SSD, SST2VAL, SST2WFA, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

if nargin < 4
   error('EXTRACT_SST: Too few input arguments')
elseif nargin > 4
   error('EXTRACT_SST: Too many input arguments')
end

if is_sst(sst)
   if iscell(sst)
      for m = 1:numel(sst)
         sub_sst{m} = EXTRACT_SST(sst{m},t1,t2,edge_mode);
      end
   else
      sub_sst = EXTRACT_SST(sst,t1,t2,edge_mode);
   end
else
   error('EXTRACT_SST: Not a valid Start/Stop Time Argument')
end

%%   
function sub_sst = EXTRACT_SST(sst,t1,t2,edge_mode) 

[N1 P1] = search_sst(t1,sst);
[N2 P2] = search_sst(t2,sst);

% 'first' and 'last' refer to the first and last events within the time
%  span defined by t1 and t2. N1 is the event number within sst
%  corresponding to t1, and P1 is the corresponding event position with
%  relation to t1. P1 = 1 if t1 falls inside the event time. P1 = 0 if t1
%  is before the start of the event.

if P1 == 1 
   if strcmpi(edge_mode,'part')
      first = [t1 sst(N1,2)];
   elseif strcmpi(edge_mode,'delete')
      first = [];
   elseif strcmpi(edge_mode,'keep')
      first = sst(N1,:);
   end    
elseif P1 == 0
   first = sst(N1,:);
end

if P2 == 1 
   if strcmpi(edge_mode,'part')
      last = [sst(N2,1) t2];
   elseif strcmpi(edge_mode,'delete')
      last = [];
   elseif strcmpi(edge_mode,'keep')
      last = sst(N2,:);
   end    
elseif P2 == 0
   last = [];
end

sub_sst = [first; sst(N1+1:N2-1,:); last];