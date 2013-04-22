function print_debug(the_text, level)
% PRINT_DEBUG optionally display text based on the debug level.
%
%    PRINT_DEBUG is useful for controlling the level of verboseness in a MATLAB application.
%    You use it to specify the debug level (an integer) at which to display a certain message.
%    
%    EXAMPLE:
%
%    debug.print_debug('Welcome to MyApp', 1)
%    outfile = 'myapp.txt';
%    debug.print_debug(sprintf('output filename = %s',outfile), 3)
%
%    If the debug level is set at 0, nothing will display.
%    If set at 1 (or 2), 'Welcome to MyApp' would display.
%    if set at 3 (or higher) 'Welcome to My App', 'output filename = myapp.txt' would display.
%
%    To set the debug level, use set_debug.
% 
%    See also debug.set_debug, debug.printfunctionstack, debug.get_debug, setpref, getpref.

% AUTHOR: Ronni Grapenthin and Glenn Thompson, UAF-GI
% $Date: 2012-04-11 08:15:09 -0800 (Wed, 11 Apr 2012) $
% $Revision: 348 $
% Modified by Glenn Thompson: 2010-03-10: Added error handling for case that runmode pref hasn't been set
% Modified by Glenn Thompson: 2010-03-10: To use multiple levels of debug (0 = none, 1 = some, 2 = higher):

   try	
    	if(getpref('runmode', 'debug') >= level)
     		disp(the_text);
        end
   catch
	% the runmode preference probably has not been set, so set it here
	setpref('runmode', 'debug', 0);
   end

return 
