function value = print_debug(level, varargin)
% PRINT_DEBUG optionally display text based on the debug level.
%
%    PRINT_DEBUG is useful for controlling the level of verboseness in a MATLAB application.
%    You use it to specify the debug level (an integer) at which to display a certain message.
%    
%    EXAMPLE:
%
%
%    debug.print_debug(1, 'Welcome to MyApp')
%    outfile = 'myapp.txt';
%    debug.print_debug(3, 'output filename = %s',outfile)
%
%
%    If the debug level is set at 0, nothing will display.
%    If set at 1 (or 2), 'Welcome to MyApp' would display.
%    if set at 3 (or higher) 'Welcome to My App', 'output filename = myapp.txt' would display.
%
%    To set the default debug level, use set_debug (only applicable after restart or "clear functions".
%    To change the level temporarily call with only the new level.
%    libgt.print_debug(NewLevel);
% 
%    See also debug.set_debug, debug.printfunctionstack, debug.get_debug, setpref, getpref.

% AUTHOR: Ronni Grapenthin and Glenn Thompson and Celso Reyes, UAF-GI
% $Date: 2012-04-11 08:15:09 -0800 (Wed, 11 Apr 2012) $
% $Revision: 348 $
% Modified by Glenn Thompson: 2010-03-10: Added error handling for case that runmode pref hasn't been set
% Modified by Glenn Thompson: 2010-03-10: To use multiple levels of debug (0 = none, 1 = some, 2 = higher, etc.):
% Modified by Celso Reyes: 2015: made value persistent to speed up,flipped
% arguments, allowed for multiple arguments to make calling routines easier
% to read function.
% Glenn Thompson 2015: restored order of verboseness (increasing numbers =
% more verbose). Implemented workarounds for set_debug and get_debug.

    value = [];
    persistent Lev

    if isempty(Lev) % if Lev not already set
        Lev = 0;
    end
    if ~exist('level','var') % this is for debug.get_debug()
        value = Lev;
        return
    end
    if numel(varargin) == 0 % this is for debug.set_debug(level)
        Lev = level;
        return
    end
    if level <= Lev % the main thing - printing out based on Lev
        if numel(varargin) == 1
         disp(varargin{:});
        else
         fprintf(varargin{:});
         fprintf('\n');
        end
    end

end
