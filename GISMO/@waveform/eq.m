function [ result ] = eq( w1, w2 )
%EQ Check if waveform objects are equal
%   result = eq(w1, w2)
%   Check the scnl, start and end times, and data in two waveform objects

% Author: Glenn Thompson, Geophysical Institute, Univ. of Alaska Fairbanks
% Modified: Celso Reyes
% $Date: $
% $Revision: $

assert(isa(w1,'waveform') || isa(w2, 'waveform'));

result = false;
if w1.cha_tag == w2.cha_tag
   if (get(w1,'timevector') == get(w2,'timevector'))
      if (get(w1, 'data') == get(w2, 'data'))
         result = true;
      end
   end
end


