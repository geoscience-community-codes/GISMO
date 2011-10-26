function pathName = getpath(varargin)

%GETPATH returns a path to GISMO toolbox(es)
% MYPATHNAME = GETPATH will return a character string equivalent to the path to
% the root GISMO directory (e.g. /usr/local/GISMO_r306/GISMO)
%
% See also admin.which admin.remove admin.refresh


% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: 2010-02-04 11:51:43 -0900 (Thu, 04 Feb 2010) $
% $Revision: 178 $

  
if ~isempty(varargin)
    functionName = varargin{1};
else 
    functionName = 'startup_GISMO';
end



% GET PATH TO FUNCTION
if ~ischar(functionName)
    error('Argument must be a character string');
end

[pathName, ~, ~] = fileparts(which(functionName));
