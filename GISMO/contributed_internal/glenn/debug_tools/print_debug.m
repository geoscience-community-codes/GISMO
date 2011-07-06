function print_debug(the_text, level)
% PRINT_DEBUG
% Takes one parameter which is being printed (using disp) if program is in debug mode at a high enough level
%
% Author: Ronni Grapenthin, UAF-GI
% See also: DEBUG
% Last Modified: 2009-12-11
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
