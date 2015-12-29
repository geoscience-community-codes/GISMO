function [results, loc] = ismember(mywave,anythingelse)
   %ISMEMBER waveform implementation of ismember
   % currently only works for comparison to scnlobjects
   %
   % TRUE for each waveform that matches any scnl in the anythingelse array.
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   c = class(anythingelse);
   switch c
      case {'scnlobject','ChannelTag'}
         [results, loc]  = ismember(get(mywave,'scnlobject'),anythingelse);
      otherwise
         error('Waveform:ismember:classMismatch',...
            'Waveform does not know how to determine if it is a member of a %s class',...
            c);
   end
end