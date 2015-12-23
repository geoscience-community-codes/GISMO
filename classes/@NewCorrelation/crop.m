function c = crop(c,varargin)
   %crop   crop all waveforms to a time window
   % c = CROP(c,[PRETRIG POSTTRIG])
   % This function crop all waveforms to a time window defined by pretrig and
   % posttrig. Pretrig and posttrig are values in seconds relative to the
   % trigger time. The START field is adjusted for the new trace start times.
   % Any missing data is replaced with zeros. Typically this operation will
   % be used after traces have been aligned on a common trigger (with
   % ADJUSTTRIG).
   %
   % c = CROP(c,PRETRIG,POSTTRIG) Alternate input format. Included for backward
   % compatibility. The first usage is more consistent with other uses of
   % PRETRIG and POSTTRIG.
   %
   % EXAMPLE:
   %    C = CROP(C,[-3 5])
   %    CROPS the traces to 8 seconds in length beginning 3 seconds before the
   %    trigger.
   %
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   
   % READ & CHECK ARGUMENTS
   
   
   if (nargin==3)
      pretrig =  varargin{1};
      posttrig = varargin{2};
   elseif (nargin==2)
      tmp = varargin{1};
      if numel(tmp)~=2
         error('When CROP has only two arguments, the latter must be a two element vector. See HELP CORRELATION/CROP')
      end
      pretrig = tmp(1);
      posttrig = tmp(2);
   else
      error('Wrong number of inputs');
   end;
   
   %added cr
   pretrig= pretrig(1);
   posttrig=posttrig(1);
   
   % CROP EACH TRACES
   sampRate = c.samplerate;
   wStarts = c.traces.firstsampletime();
   imax = numel(wStarts);
   Mo = c.data_length;
   M = round(sampRate*(posttrig-pretrig));
   wstartrel = 86400*(wStarts-c.trig);	% relative start time, typically negative
   s1_all = round(sampRate * (wstartrel - pretrig));
   samp_per_day = 86400 * sampRate;
   %%start2 = zeros(imax,1);
   d = double(c.traces);
   for i = 1:imax
      %samples to pad or crop
      w2 = zeros(M,1);
      if s1_all(i) > 0                         % beginning of traces must be PADDED
         s2 =  min([Mo M-s1_all(i)]);         % number of data samples to include
         w2(s1_all(i)+1:s1_all(i)+s2) = d(1:s2,i);     % Pad beginning with zeros
         start2 = wStarts(i)-(s1_all(i))/samp_per_day;
      else
         s1 = -1*s1_all(i);                   % beginning of traces must be CLIPPED
         s2 =  min([Mo-s1 M]);         % number of data samples to include
         w2(1:s2) = d(s1+1:s1+s2,i);     % crop beginning
         start2 = wStarts(i)+(s1)/samp_per_day;
      end;
      c.traces(i).data = w2;
      c.traces(i).start = start2;
   end;
   % c.traces = addhistory(c.traces,'correlation/crop');
end

