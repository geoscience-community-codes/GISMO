function sst_out = add_sst(sst_1,sst_2,varargin)
%ADD_SST: Combine 2 sets of SST (Event start/stop times)
%
%USAGE: sst_out = add_sst(sst_1,sst_2)      - Default, combine w/o merge
%       sst_out = add_sst(sst_1,sst_2,mode) - Only 'merge' is implemented
%
%INPUTS: sst_1 - SST set 1
%        sst_2 - SST set 2
%        mode  - Optional - Only 'merge' is implemented, merges SST that
%                overlap
%
%OUTPUTS: sst_out - Resulting SST output
%
% See also ADD_SST, CHK_T, COMPARE_SST, DELETE_SST, EXTRACT_SST, IS_SST,  
%          ISTEQUAL, MERGE_SST, SEARCH_SST, SORT_SST, NAN2SST, SSD2SST,  
%          SST2NAN, SST2SSD, SST2VAL, SST2WFA, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

% TO-DO - Documentation

%%
method = 0; % default method, don't merge new sst
if nargin < 2
   error('ADD_SST: Too few input arguments')
elseif nargin > 3
   error('ADD_SST: Too many input arguments')
elseif nargin == 3
   switch lower(varargin{1})
      case 'merge'
         method = 1; % merge new sst
   end
end

%%
s1 = size(sst_1,1);
s2 = size(sst_2,1);
if s1==0 && s2==0
   sst_out = []; return
elseif s1==0 && s2>0
   sst_out = sst_2; return
elseif s2==0 && s1>0
   sst_out = sst_1; return
else 
   if s1 >= s2
      % Good to go
   elseif s2 > s1 % Swap sst_1 and sst_2 variables
      sst_temp = sst_1; stemp = s1;
      sst_1 = sst_2; s1 = s2;
      sst_2 = sst_temp; s2 = stemp;  
   end
   
   for n = 1:s2
      x = sst_2(n,:);
      [N P] = search_sst(x(1),sst_1);
      if N == 1 && P == 0
         sst_1 = [x; sst_1];
      elseif N == 1 && P == 1
         sst_1 = [sst_1(1,:); x; sst_1(2:end,:)];
      elseif N == s1 && P == 1
         sst_1 = [sst_1; x];
      elseif N == s1+1 && P == 0
         sst_1 = [sst_1; x];
      elseif P == 0
         sst_1 = [sst_1(1:N-1,:); x; sst_1(N:end,:)];
      elseif P == 1
         sst_1 = [sst_1(1:N,:); x; sst_1(N+1:end,:)];
      end
      s1 = size(sst_1,1);
   end
   if method == 1
   sst_1 = merge_sst(sst_1);
   end
end

sst_out = sst_1;