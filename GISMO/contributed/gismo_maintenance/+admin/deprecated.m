function deprecated(currentMFile,varargin)

%DEPRECATED issue a deprication warning
% DEPRECATED(MFILENAME) warns the user that the current function has 
% been deprecated and is slated for eventual removal from GISMO.
%
% DEPRECATED(CURRENTFUNCTION,NEWMFILE) points the user toward a newer
% function intended to replace the deprecated function.
%
% ** HINT: In most cases the first argument can be short-handed using the
% built-in function mfilename:
%   deprecated(mfilename);

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: 2010-02-04 11:51:43 -0900 (Thu, 04 Feb 2010) $
% $Revision: 178 $



% CHECK ARGUMENTS
if ~exist('currentMFile')
    error('admin:deprecated','admin.deprecated requires at least one string argument.');
end 
if ~isempty(varargin)
    newMFileExists = 1;
    newMFile = varargin{1};
else
    newMFileExists = 0;
    newMFile = '-';
end
if ~ischar(currentMFile) || ~ischar(newMFile)
   error('admin:deprecated','function arguments must be character strings'); 
end


% ISSUE DEPRICATION WARNING
if isempty(varargin)
    warning(['The function ' currentMFile ' has been deprecated and will be removed from GISMO']);
else    
    warning(['The function ' currentMFile ' has been deprecated and will be removed from GISMO. Use ' newMFile ' instead.']);
end