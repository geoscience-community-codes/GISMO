function set_debug(debuglevel)
% SET_DEBUG set the debug level.
%
%    SET_DEBUG is used in conjunction with PRINT_DEBUG to control the verboseness of MATLAB output.
%    You use it to specify the debug level (an integer) at which to display a certain message.
%    
%    EXAMPLE:
%    Set the debug level to 1:
%        libgt.set_debug(1)
% 
%    See also print_debug, setpref.

% AUTHOR: Ronni Grapenthin and Glenn Thompson, UAF-GI
% $Date:$
% $Revision:$
% Modified by Glenn Thompson: 2010-03-10: To use multiple levels of debug (0 = none, 1 = some, 2 = higher)

	setpref('runmode', 'debug', debuglevel);

return
