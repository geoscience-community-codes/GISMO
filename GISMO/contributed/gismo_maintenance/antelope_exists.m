function TF = antelope_exists()

%ANTELOPE_EXISTS check for Antelope Toolbox for Matlab
%  TF = ANTELOPE_EXISTS returns 1 if the Antelope Toolbox for Matlab is
%  present in the path. This function does not check to see whether the
%  Antelope Toolbox is functioning correctly. It merely searches the path
%  for functions. The Antelope Toolbox for Matlab is maintained by Kent
%  Lindquist of Lindquist Consulting.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: 2010-02-04 11:51:43 -0900 (Thu, 04 Feb 2010) $
% $Revision: 178 $



if exist('dbopen','file') && exist('trload_css','file');
    TF = 1;
else
    TF = 0;
end