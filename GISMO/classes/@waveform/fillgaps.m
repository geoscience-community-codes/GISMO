function w = fillgaps(w,value, gapvalue)
   % FILLGAPS - fill missing data with values of your choice
   % W = fillgaps(W,number) fills data with the number of your choice
   %   "number" can also be nan or inf or -inf
   %
   % W = fillgaps(W,[]) removes missing data from waveform.  Warning, the
   %   resulting timing issues are NOT corrected for!
   %
   % W = fillgaps(W,'method') replaces data using an interpolation method of
   % your choice. intended methods include:
   % 'meanAll',
   % 'meanEndpoints'  CURRENTLY UNIMPLEMENTED.
   % or some such equivalent undreamed of by me.
   %
   % FILLGAPS is designed to replace NaN values.  However, if if you use
   % W = fillgaps(W,number, gapvalue), then ALL data points with the value
   % GAPVALUE will be replaced by NUMBER.
   
   if ~(isnumeric(value) && (isscalar(value) || isempty(value)) || ischar(value))
      warning('Waveform:fillgaps:invalidGapValue',...
         'Value to replace data with must be string or scalar or []');
   end
   
   if ~exist('gapvalue','var') || isnan(gapvalue)
      getgaps = @(x) isnan(x.data);
   else
      getgaps = @(x) x.data == gapvalue;
   end;
   
   if ischar(value)
      fillmethod = lower(value);
   else
      fillmethod = 'number';
   end
   
   switch fillmethod
      case 'meanall'
         for N = 1:numel(w);
            allgaps = getgaps(w(N));
            % do not include the values to be replaced
            meanVal = mean(w(N).data(~allgaps));
            if isnan(meanVal)
               meanVal = 0;
            end
            w(N).data(allgaps) = meanVal;
         end
      case 'number'
         for N = 1:numel(w);
            w(N).data(getgaps(w(N))) = value;
         end
      otherwise
         error('waveform:fillgaps:unimplementedMethod',...
            'Unimplemented fillgaps method [%s]', fillmethod);
   end
end