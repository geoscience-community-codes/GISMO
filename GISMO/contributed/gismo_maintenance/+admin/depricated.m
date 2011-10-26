function depricated(currentMFile,varargin)

%DEPRICATED(MFILENAME) issues a deprication warning
% DEPRICATED warns the user that the current function has been depricated
% and is slated for eventual removal from GISMO.
%
% HINT: In most cases the first argument can be short-handed using the
% built-in function mfilename:
%   depricated(mfilename);
%
% DEPRICATED(CURRENTFUNCTION,NEWMFILE) points the user toward a newer
% function intended to replace the depricated function.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: 2010-02-04 11:51:43 -0900 (Thu, 04 Feb 2010) $
% $Revision: 178 $



% CHECK ARGUMENTS
if ~exist('currentMFile')
    error('admin:depricated','admin.depricated requires at least one string argument.');
end 
if ~isempty(varargin)
    newMFileExists = 1;
    newMFile = varargin{1};
else
    newMFileExists = 0;
    newMFile = '-';
end
if ~ischar(currentMFile) || ~ischar(newMFile)
   error('admin:depricated','function arguments must be character strings'); 
end


% ISSUE DEPRICATION WARNING
if isempty(varargin)
    warning(['The function ' currentMFile ' has been depricated and will be removed from GISMO']);
else    
    warning(['The function ' currentMFile ' has been depricated and will be removed from GISMO. Use ' newMFile ' instead.']);
end