function debuglevel=get_debug()
%% GET_DEBUG get the debug level.
%
%    GET_DEBUG return the current level of verboseness of MATLAB output.
%    
%    EXAMPLE:
%        verboseness = debug.get_debug()
% 
%    See also debug.set_debug, debug.print_debug, debug.printfunctionstack, setpref.

% AUTHOR: Glenn Thompson, UAF-GI

debuglevel = debug.print_debug();

return 
