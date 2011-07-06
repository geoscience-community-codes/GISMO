function debug(debuglevel)
% DEBUG 
%
% Author: Ronni Grapenthin, UAF-GI
% See also: PRINT_DEBUG
% Last Modified: 2009-12-11
% Modified by Glenn Thompson: 2010-03-10: To use multiple levels of debug (0 = none, 1 = some, 2 = higher):
	setpref('runmode', 'debug', debuglevel);

return
