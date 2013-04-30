function cpath=catpath(varargin);
% CATPATH concatenate paths, whether its a Unix or Windows based system
%
% Usage:
%   [cpath]=catpath(varargin)
%
% INPUTS:
%   varargin        - any number of path elements (rootpath, subdir, subsubdir, ...)
%
% OUTPUTS:
%   cpath           - concatenated path
%
% EXAMPLE:
%   cpath=catpath("home","glenn","mfiles","lib") would return:
%       /home/glenn/mfiles/lib on a Unix system, and
%       \home\glenn\mfiles\lib on a Windows system
% 
% SEE ALSO:
%   basename

% AUTHOR: Glenn Thompson, University of Alaska Fairbanks
% $Date$
% $Revision$

% Obsolete because MATLAB now uses filesep()
%if(isunix)
%    path_separator='/';
%elseif(ispc)
%    path_separator='\';
%else
%    error('catpath: Dont know what kind of OS you are using, but it isnt Solaris, Linux or Windows');
%end

cpath=varargin{1};
for i=2:length(varargin)
    cpath=[cpath,filesep,varargin{i}];
end
return;
