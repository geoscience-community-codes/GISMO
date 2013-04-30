function [filename, dirname, fileroot, fileext] = basename(fullpath)
%BASENAME returns parts of a filepath
% [filename, dirname, fileroot, fileext] = basename(fullpath)
% e.g.:
%     [bname, dname, base, ext] = basename('/dir/base.ext')
% returns:
%  
%  bname = "base.ext", dname = "/dir", base = "base", ext = "ext"
%
% USE OF THIS FUNCTION IS NOT RECOMMENDED because MATLAB now includes
% fileparts(). Indeed, basename is now a much shorter code because it
% uses fileparts(). The problem with fileparts is the the "." is included
% in the extension, and the fileroot is not returned. Although in 
% situations where you simply want to replace one ext with another, you
% can use strrep().

%    See also: fileparts

% AUTHOR: Glenn Thompson, University of Alaska Fairbanks
% $Date$
% $Revision$

[dirname, filename, ext] = fileparts(fullpath);

fileroot = filename; fileext = '';
i = findstr(filename, '.');
if length(i)>0
        fileroot = filename(1:i(end)-1);
        fileext = filename(i(end)+1:end);
end
