function varargout = chk_t(type,varargin)
%
%CHK_T: Check that all time inputs are valid, then output them in the 
%       format specified by 'type'
%
%USAGE: varargout = chk_t(type,varargin) 
%                   (length of varargin equals length of varargout)
%             i.e.    
%                   [t1 t2 t3] = chk_t(type,t1,t2,t3)
%
%INPUTS: type     - output format ('num','str', or 'vec')
%        varargin - input time arguments
%
%OUTPUTS: varargout - output time arguments
%
% See also ADD_SST, CHK_T, COMPARE_SST, DELETE_SST, EXTRACT_SST, IS_SST,  
%          ISTEQUAL, MERGE_SST, SEARCH_SST, SORT_SST, NAN2SST, SSD2SST,  
%          SST2NAN, SST2SSD, SST2VAL, SST2WFA, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

if nargin-1~=nargout
   error('CHK_T: Number of time inputs must equal number of outputs')
end

for n=1:nargin-1
   t = varargin{n};
   if ischar(t)
      t = datenum(t);
   end
   if isnumeric(t) && size(t,1)==1 && size(t,2)==6
      t = datenum(t);
   elseif isnumeric(t) && size(t,1)==1 && size(t,2)==5
      t = [t 0];
      t = datenum(t);
   elseif isnumeric(t) && size(t,1)==1 && size(t,2)==4
      t = [t 0 0];
      t = datenum(t);
   elseif isnumeric(t) && size(t,1)==1 && size(t,2)==3
      t = [t 0 0 0];
      t = datenum(t);
   end
   if numel(t)==1 && isnumeric(t) && t>693962 && t<(now+365)
      % Valid between 1900-01-01 and 1 year from today
      switch lower(type)
         case 'num'
            % good to go
         case 'str'
            t = datestr(t,0);
         case 'vec'
            t = datevec(t);
      end
   varargout(n) = {t};   
   else
      disp(['Time Argument ',num2str(n),' is not valid'])
      varargout(n) = {NaN};  
   end
end
      