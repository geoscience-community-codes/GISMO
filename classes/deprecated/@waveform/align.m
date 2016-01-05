function w = align(w,alignTime, newFrequency, method)
   %ALIGN resamples a waveform at over a specified interval
   %   w = align(waveform, alignTime, newFrequency)
   %   w = align(waveform, alignTime, newFrequency, method)
   %
   %   Input Arguments
   %       WAVEFORM: waveform object       N-dimensional
   %       ALIGNTIME: either a single matlab time or a series of times the
   %       same shape as the input WAVEFORM matrix.
   %       NEWFREQUENCY: the frequency (Samples per Second) of the newly aligned
   %          waveforms
   %       METHOD: Any of the methods from function INTERP
   %          If omitted, then the DEFAULT IS 'pchip'
   %
   %   Output
   %       The output waveform has the new frequency newFrequency and a
   %       starttime calculated by the specified method, using matlab's
   %       INTERP1 function.
   %
   %
   %   METHODOLOGY
   %     The alignTime is projected forward or backward in time at the
   %     specified sample interval until it approaches the original waveform's
   %     start time.  The rest of the waveform is then interpolated at the
   %     sample frequency.
   %
   %     Methodology Example.
   %         A waveform starts on 1/1/2008 12:00, with sample freq of 10
   %         samples/sec, and has data covering 10 minutes  (6000 samples).
   %         The resampled data is requested for time 1/1/2008 12:05:00.03,
   %         also at 10 samples/sec.
   %         The resulting data will start at 1/1/2008 12:00:00.3, and have
   %         5999 samples, with the last sample occurring at 12:09:59.830.
   %
   %   Examples of usefulness?  Particle motions, coordinate transformations.
   %   If used for particle motions, consider MatLab's plotmatrix command.
   %
   %   example:
   %       scnl = sclnobject('KDAK',{'BHZ','BHN','BHE'}); %grab all 3 channels
   %       % for each component, grab winston data on Kurile Earthquake
   %       w = waveform(mydatasource,scnl,'1/13/2007 04:20:00',...
   %         '1/13/2007 04:30:00');
   %       w = align(w,'1/37/2007 4:22:00', get(w(1),'freq'));
   %
   %
   % See also INTERP1, PLOTMATRIX
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   persistent oneSecond
   if isempty(oneSecond)
      oneSecond = datenum([0 0 0 0 0 1]);
   end
   
   if ~exist('method','var')
      method = 'pchip';
   end
   
   if ischar(alignTime),
      alignTime =  datenum(alignTime);
   end
   
   hasSingleAlignTime = numel(alignTime) == 1;
   
   if hasSingleAlignTime %use same align time for all waveforms
      alignTime = repmat(alignTime,size(w));
   elseif isvector(alignTime) && isvector(w)
      if numel(alignTime) ~= numel(w)
         error('Waveform:align:invalidAlignSize',...
            'The number of Align Times does not match the number of waveforms');
      else
         % this situation OK.
         % ignore possibility that we're comparing a 1xN vs Nx1.
      end
   elseif ~all(size(alignTime) == size(w)) %make sure 1:1 ratio for alignTime & waveform
      if numel(alignTime) == numel(w)
         error('Waveform:align:invalidAlignSize',...
            ['The alignTime matrix is of a different size than the '...
            'waveform Matrix.  ']);
      end
   end
   
   
   newSamplesPerSec = 1 / newFrequency ;  %# samplesPerSecond
   timeStep = newSamplesPerSec * oneSecond;
   existingStarts = get(w,'start');
   existingEnds = get(w,'end');
   
   % calculate the offset of the closest "aligned" time, by projecting the
   % desired frequency rate and time forward or backward onto these waveforms'
   % start time.
   deltaTime = existingStarts - alignTime;  % time in between
   % if deltatime (-):alignTime AFTER existingStarts,
   % if deltatime (+):alignTime BEFORE existingStarts
   closestStartTime = existingStarts - rem(deltaTime,timeStep);
   
   for n=1:numel(w)
      origTimes = get(w(n),'timevector');
      % newTimes MUST be in one column, else DATA field gets corrupted
      newTimes = ( closestStartTime(n):timeStep:existingEnds(n) )';
      
      %get rid of samples that lay entirely outside the existing waveform's
      %range (ie, only interpolate values BETWEEN points)
      newTimes(newTimes < origTimes(1) | newTimes > origTimes(end)) = [];
      
      w(n).data = interp1(...
         origTimes,...     original times (x)
         w(n).data,...         original data (y)
         newTimes,...    new times (x1)
         method);           %  method
      w(n).start = newTimes(1); % must be a datenum
   end
   w = set(w,'freq',newFrequency);
   
   %% update histories
   % if all waves were aligned to the same time, then handle all history here
   if hasSingleAlignTime
      noteRealignment(w, alignTime(1), newFrequency);
   else
      for n=1:numel(w)
         w(n) = noteRealignment(w(n), alignTime(n), newFrequency);
      end
   end
end

function w = noteRealignment(w, startt, freq)
   timeStr = datestr(startt,'yyyy-mm-dd HH:MM:SS.FFF');
   myHistory = sprintf('aligned data to %s at %f samples/sec', timeStr, freq);
   w = addhistory(w,myHistory);
end
