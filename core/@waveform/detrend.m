function w = detrend (w, varargin)
   %DETREND remove linear trend from a waveform
   %   waveform = detrend(waveform, [options])
   %   removes the linear trend from the waveform object(s).
   %
   %   Input Arguments
   %       WAVEFORM: a waveform object   N-DIMENSIONAL
   %       OPTIONS: optional parameters as described in matlab's DETREND
   %
   %  Missing values in GISMO should be marked with NaN. waveform/detrend
   %  attempts to handle these smartly. Any leading or trailing NaNs are
   %  temporarily removed, leaving data from the first real value to the
   %  last real value. Any NaNs within this sequence are temporarily
   %  replaced via linear interpolation, then the sequence is detrended.
   %  Then the removed NaNs are all put back in.
   %
   %  If you wish to handle missing values (NaNs) in a different way, do so
   %  before calling waveform/detrend.
   %
   % See also DETREND for list of options
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   % Modified by Glenn Thompson 20170328 to handle missing values (marked
   % by NaN) smartly.
   % $Date$
   % $Revision$
   
   Nmax = numel(w);
   warnedAboutNAN = false;
   for I = 1 : Nmax
      
      if isempty(w(I)), continue, end
      
      d = w(I).data;
      if ~warnedAboutNAN && any(isnan(d))
         warnedAboutNAN = true;
         warning('Waveform:detrend:NaNwarning',...
            ['NaN values exist in one or more waveforms.',...
            '  Attempting to deal with these in a smart way']);
      end
      
      % 20170328 New code added by Glenn Thompson to deal with leading or
      % trailing NaN. It finds the first & last non-NaN value, and only
      % tries to detrend that section of the data. 
      % Between the first and last non-NaN value, it temporarily fills any
      % intervening NaNs via linear interpolation. Then puts them back in
      % after detrending.
      % The overall result is that NaNs are preserved, but the good data
      % should also get detrended. A more sophisticated method might define
      % breakpoints for detrending.
      good_data_indices = find(~isnan(d));
      first_good_index = good_data_indices(1);
      last_good_index = good_data_indices(end);
      d2 = d(first_good_index:last_good_index);
      still_missing_data_indices = find(isnan(d2));
      d2(isnan(d2)) = interp1(find(~isnan(d2)), d2(~isnan(d2)), find(isnan(d2)),'linear');
      d2 = detrend(d2,varargin{:});
      d2(still_missing_data_indices) = NaN;
      d(first_good_index:last_good_index) = d2;
      
      %w(I).data = detrend(d,varargin{:});
      w(I).data = d;
   end
end
