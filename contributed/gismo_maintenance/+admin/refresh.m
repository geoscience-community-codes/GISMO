function refresh()

%REFRESH refresh all paths in GISMO
% REFRESH refresh all paths in GISMO. This is useful when adding new
% functions and packages. These are not always recognized on the fly by
% Matlab.
%
% See also admin.which admin.remove admin.getpath


% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


import admin.*

which(getpath);