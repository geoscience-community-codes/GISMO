function [N P] = search_sst(t,sst)

%SEARCH_SST: Function accepts a reference datenum t and a nx2 array of
%  datenum Start/Stop Times. The SST element containing time t, or the
%  SST element preceding t will be returned in output N, with output P
%  indicating whether the t is inside of sst(N,:), or between sst(N-1,2)
%  and sst(N,1). This function can be used to find a sst element, or locate
%  a place between elements to place a new sst element.
%
%USAGE: [N P] = search_sst(t,sst)
%
%INPUTS: t --> reference time (datenum) to be located
%        sst --> nx2 Start/Stop Time (datenum) array to search in  
%
%OUTPUTS: N --> if P==1, t is inside sst(N,:)
%               if P==0, t is between sst(N-1,2) and sst(N,1)
%         P --> Indicates whether t is inside of, or before sst(N,:)
%               1 --> inside, 0 --> before
%
% See also ADD_SST, CHK_T, COMPARE_SST, DELETE_SST, EXTRACT_SST, IS_SST,  
%          ISTEQUAL, MERGE_SST, SEARCH_SST, SORT_SST, NAN2SST, SSD2SST,  
%          SST2NAN, SST2SSD, SST2VAL, SST2WFA, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

%%
max_n = size(sst,1);  % initialize upper search bound
min_n = 1;            % initialize lower search bound
if t < sst(1,1)       % t is before all sst
   N = 1;             % First sst element: sst(1,:)
   P = 0;             % Before sst(1,:)
   return
elseif t > sst(end,2) % t is after all sst
   N = max_n+1;       % Use with caution, N here is out of sst bounds
   P = 0;             % Before sst(end+1,1) --> does not exist
   return
end

%%
N = 0;
while N == 0
   mid_n = ceil(min_n+(max_n-min_n)/2); % Move mid_n to middle of range
   if t >= sst(mid_n,1)
      if t <= sst(mid_n,2)
         N = mid_n;       % Found t inside sst(N,:)
         P = 1;           % Indicates t is inside 1 sst
      elseif t < sst(mid_n+1,1)
         N = mid_n+1;     % Found t between sst(N,2) and sst(N+1,1)
         P = 0;           % Indicates t is between 2 sst
      else
         min_n = mid_n+1; % Adjust lower search bound
      end
   else
      max_n = mid_n-1;    % Adjust upper search bound
   end      
end

%% If there exist multiple overlapping sst elements, find the very first
%  sst element that contains time t, and return refernce N for this element 
if P == 1
   first = 0;
   while first == 0
      if N > 1
         if t >= sst(N-1,1) && t <= sst(N-1,2)
            N = N-1;
         else
            first = 1;
         end
      else
         first = 1;
      end
   end
end
