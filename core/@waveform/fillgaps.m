function w = fillgaps(w,value, gapvalue)
   % FILLGAPS - fill missing data with values of your choice
   % W = fillgaps(W,number) fills data with the number of your choice
   %   "number" can also be nan or inf or -inf
   %
   % W = fillgaps(W,[]) removes missing data from waveform.  Warning, the
   %   resulting timing issues are NOT corrected for!
   %
   % W = fillgaps(W,'method') replaces data using an interpolation method of
   % your choice. Methods are:
   %
   %    'meanall' - replace missing values with the mean of the whole
   %    dataset
   %
   %    'number' - replace missing value with a numeric value of your
   %    choice (can also be Inf, -Inf, NaN)
   %
   %    'interp' - assuming missing values are marked by NaN, this will use
   %    cubic interpolation to estimate the missing values
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
       case 'interp' % blame Glenn, inspired by http://www.mathworks.com/matlabcentral/fileexchange/8225-naninterp by E Rodriguez
           for N = 1:numel(w);
               X = get(w(N),'data');
               X(isnan(X)) = interp1(find(~isnan(X)), X(~isnan(X)), find(isnan(X)),'spline');
               w(N) = set(w(N),'data',X);
           end
      otherwise
         error('waveform:fillgaps:unimplementedMethod',...
            'Unimplemented fillgaps method [%s]', fillmethod);
   end
end