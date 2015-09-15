function [ result ] = eq( w1, w2 )
   %EQ Check if waveform objects are equal
   %   result = eq(w1, w2)
   %   Check the scnl, start and end times, and data in two waveform objects
   
   % Author: Glenn Thompson, Geophysical Institute, Univ. of Alaska Fairbanks
   % Modified: Celso Reyes
   % $Date: $
   % $Revision: $
   
   assert(isa(w1,'waveform') || isa(w2, 'waveform'));
   
   result = w1.cha_tag == w2.cha_tag &&...
      w1.start == w2.start && ...
      w1.freq == w2.freq && ...
      all(w1.data == w2.data);
end

