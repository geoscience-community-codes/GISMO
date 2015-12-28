function c = taper(c,varargin)
   
   %TAPER tapers the ends of waveforms in the correlation object.
   %
   %C = TAPER(C,R) applies a cosine taper to the ends of a trace where r is
   % the ratio of tapered to constant sections and is between 0 and 1. For
   % example, if R = 0.1 then the taper at each end of the trace is 5% of the
   % total trace length. Note that if R is set to 1 the resulting taper is a
   % hanning window. This is a wrapper script to the taper function in the
   % waveform toolbox. See HELP
   % WAVEFORM/TAPER for specifics.
   %
   %C = TAPER(C) same as above with a default taper of R = 0.2.
   %
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   
   % READ & CHECK ARGUMENTS
   
   
   % GET TAPER STYLE
   if ~isempty(varargin) && ischar(varargin{end})
      style = varargin{end};
      varargin = varargin(1:end-1);
   else
      style = 'cosine';
   end
   
   % COSINE TAPER
   switch upper(style)
      case 'COSINE'
         if length(varargin)==1
            R = varargin{1};
         elseif isempty(varargin)
            R = 0.2;
         else
            error('Wrong number of inputs for cosine taper');
         end
      otherwise
         % do nothing
   end
   
   
   % APPLY TAPER
   c.traces = c.traces.taper(style, R);
end



