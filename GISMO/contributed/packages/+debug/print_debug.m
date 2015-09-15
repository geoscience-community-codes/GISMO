function print_debug(level, varargin)
% PRINT_DEBUG optionally display text based on the debug level.
%
%    PRINT_DEBUG is useful for controlling the level of verboseness in a MATLAB application.
%    You use it to specify the debug level (an integer) at which to display a certain message.
%    
%    EXAMPLE:
%
%
%    libgt.print_debug(1, 'Welcome to MyApp')
%    outfile = 'myapp.txt';
%    libgt.print_debug(3, 'output filename = %s',outfile)
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
% Modified by Glenn Thompson: 2010-03-10: To use multiple levels of debug (0 = none, 1 = some, 2 = higher):
% Modified by Celso Reyes: 2015: made value persistent to speed up,flipped
% arguments, allowed for multiple arguments to make calling routines easier
% to read.
% function.

persistent Lev
   if isempty(Lev)
      try
         Lev = getpref('runmode', 'debug');
      catch
         setpref('runmode','debug', 0); % might wish to alert user, or set it in a more gismo-sounding location.
         Lev = 0;
      end
   end
   if numel(varargin) == 0
      Lev = level;
      return
   end
   if level >= Lev
      if numel(varargin) == 1
         disp(varargin{:})
      else
         fprintf(varargin{:})
      end
   end
end
