function c = agc(c,windowInSeconds)
   %acg   apply automatic gain control to each trace
   %
   % This function applies automatic gain control (AGC) to each trace. This
   % process, commonly used in seismic reflection processing, applies a
   % variable scale to each trace such that the amplitude along the entire
   % trace is roughly uniform. By minimizing amplitude variations along the
   % trace, well-correlated but low-amplitude phases become more visible. A
   % time window may be specified to control how tightly this scaling is
   % applied. Use a longer window for lower frequecy signals. The function
   % returns a correlation object.
   %
   % EXAMPLES:
   %  c=agc(c)    				apply agc using the default time window (0.5 s)
   %  c=agc(c,0.8)            	apply agc using a window of 0.8 s
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   if ~exist('windowInSeconds','var')
      windowInSeconds = 0.5; 
   end
   
   agcsamp = round( windowInSeconds * c.samplerate );
   
   
   % LOOP THROUGH TRACES APPLYING GAIN
   for tracenum = 1:length(c.traces)
      d = c.traces(tracenum).data;
      scale = zeros( length(d)-2*agcsamp , 1 );
      for index=-1*agcsamp:agcsamp
         scale=scale + abs( d(agcsamp+index+1:agcsamp+index+length(scale)) );
      end;
      scale = scale/mean(abs(scale));
      scale = [ones(agcsamp,1)*scale(1) ; scale ; ones(agcsamp,1)*scale(end)];
      d = d./scale;
      c.traces(tracenum).data =  d;
   end;
   
end
