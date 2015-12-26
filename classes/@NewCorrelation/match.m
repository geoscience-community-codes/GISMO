function [c1,c2] = match(c1,c2,toleranceInSeconds)
   
   %Retain matching elements of two correlation objects.
   %
   % [C1,C2] = MATCH(C1,C2) Returns those elements of c1 and c2 which have
   % matching trigger times. Typically this will be used to sync correlation
   % objects from two different stations covering the same time frames, or
   % sync'ing two channels from the same station.
   %
   % [C1,C2] = MATCH(C1,C2,TOLERANCE) allows traces to match when their
   % trigger times are within TOLERANCE seconds of each other. When this
   % parameter is not included, the default value is 1 second.
   %
   % CAVEATS: Note that if C2 has multiple traces which match a trigger time
   % in C1, there is no way of controling which single trace in C2 will be
   % considered a match. Similarly, if C1 contains multiple traces with the
   % same trigger time, a match for each one will be found in C2.
   
   % AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   
   % READ & CHECK ARGUMENTS
   narginchk(2,3);
   
   if ~exist('tolerance','var')
      toleranceInSeconds = 1;
   end
   assert(isnumeric(toleranceInSeconds), 'Tolerance must be a number in seconds')
   
   disp(['Tolerance for successful match is: ' num2str(toleranceInSeconds) ' seconds']);
   
   
   % FIND ELEMENTS THAT MATCH
   trig1 = c1.trig;
   trig2 = c2.trig;
   matchIndex = [];
   for n = 1:numel(trig1)
      [minVal,minIndex] = min(abs(trig2 - trig1(n))*86400);
      if minVal < toleranceInSeconds
         matchIndex(n) = minIndex;
      else
         matchIndex(n) = 0;
      end
   end
   
   
   % SUBSET FIRST CORRELATION OBJECT
   index = find(matchIndex);
   c1 = subset(c1,index);
   
   % SUBSET FIRST CORRELATION OBJECT
   index = matchIndex(find(matchIndex));
   c2 = subset(c2,index);
   
end
