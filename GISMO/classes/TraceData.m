classdef TraceData
   %TraceData handles the data associated with timeseries.  
   %   Tracedata might be considered a "light" version of the timeseries
   %   class. Whereas the timeseries class has lots of functionality, it
   %   suffers from much slower execution times.
   %
   %
   % About TraceData vs Waveform
   %   Because of the ability to reference fields directly, several
   %   functions no longer are included. These include:
   %   MIN, MAX, MEDIAN, MEAN,
   %   Let T be a TraceData object, and let W be a waveform object
   %   BEFORE: 
   %      m = min(W)
   %   NOW:
   %      m = min(T.data);
   %   
   %  if T is an array of TraceData objects
   %      m = 
   
   % trying new tactic.  I won't try to anticipate all the various ways
   % someone can provide incompatible data. Instead, I'm going to provide a
   % comment with my expectations which will show up automatically in the
   % displayed error.
   
   % Waveform functions included in Tracedata:
   %  - functions that manipulate the data itself
   %
   % Waveform functions NOT added to Tracedata:
   %  - functions that require knowledge of time
   %  - functions that require knowledge of location
   %  - function that access user defined fields
   %  - functions that access history
   %  - simple statistical functions: probably min, max, median, std, var
   %  - additinal not-so-sure-we-need-these functions
   %    : getpeaks
   
   properties
      data % time-series data, kept in a column
      samplerate % in samples/sec
      units % text description of data units
   end
   
   properties(Dependent)
      duration % duration in seconds To get matlab duration, divide by 86400
   end
   
   properties(Hidden=true)
      % when trust_assignments is false, then data
      trust_assignments = false; % if not trusted, then slows down computations somewhat, but is useful for debugging. 
      debug_level
   end
   
   methods
      function obj = TraceData(varargin)
         switch nargin
            case 1
               if isa(varargin{1}, 'waveform')
                  obj.samplerate = get(varargin{1},'freq');
                  obj.data = get(varargin{1},'data');
                  obj.units = get(varargin{1}, 'units');
               end
            case 3 % TraceData(data, samplerate, units);
               obj.data = varargin{1};
               obj.samplerate = varargin{2};
               obj.units = varargin{3};
         end %switch
      end
         
      function obj = set.data(obj, values)
         % set.data ensures that data is always stored in a column
            obj.data = values(:);
      end
      
      function val = sampletimes(obj)
         % TraceData.sampletimes returns matlab-time offset of each sample
         assert(numel(obj) == 1, 'only works on one TraceData at a time');
         val = (0:(numel(obj.data)-1)) .* obj.samplerate / 86400;
         val = val(:);
      end
      
      function secondsOfData = get.duration(obj)
         %returns duration in seconds
         assert(numel(obj) == 1, 'only works on one TraceData at a time');
         secondsOfData = numel(obj.data) / obj.samplerate;
      end
      
      function s = formattedduration(obj, fmt)
         % formattedduration default format is 'dd:hh:mm:ss.SSS'
         % depends upon the duration class, introduced in r2014b
         % see duration
         secsOfData = obj.duration;
         if exist('duration','class') %available in recent r2014b and later of matlab
            if exist('fmt','var') && ~isempty(fmt)
               s = char(duration(0,0,secsOfData,'Format',fmt));
            else
               s = char(duration(0,0,secsOfData,'Format','dd:hh:mm:ss.SSS'));
            end
         else
            error('advanced duration functions supported in r2014b and later');
         end
      end
      
      %% Mathamatical - BASIC OPERATIONS
      function A = plus(A, B)
         % PLUS add something to the TraceData's data,
         %   This will return a TraceData object
         %
         %   valid combinations
         %      TraceData + NumericVector; % same length as TraceData.data
         %      TraceData + Scalar;
         %
         %  To avoid ambiguity with the metadata, two traces are added
         %  together by explicitly adding the data from one to the other:
         %
         %      % assertCompatibility(TraceData1, TraceData2); % for debug
         %      TraceData1 + TraceData2.data
         %
         % see also testCompatibility, assertCompatibility
         
         if ~isa(A, 'TraceData')
            [A, B] = deal(B, A); % swap values
         end
         
         % A is guaranteed to be TraceData
         if isnumeric(B)
            for n = 1: numel(A)
               A(n).data = A(n).data + B; % add to either a scalar or a COLUMN of numbers (same length as TraceData's data)
            end
         elseif isa(B,'TraceData')
            error('TraceData:plus:ambiguousOperation',...
               ['Adding two TraceData objects results in ambiguous metadata.'...
               '\nInstead, add the data explicitly to the Trace whose'...
               ' metadata you wish to keep.\nEx.  T = T1 + T2.data']);
         else
            error('TraceData:plus:unknownClass','do not know how to add a %s to a TraceData object', class(B));
         end
      end
       
      function A = minus(A, B)
         % MINUS add something to the TraceData's data,
         %   This will return a TraceData object
         %
         %   valid combinations (let TD represent any TraceData object)
         %      TraceData - NumericVector; % same length as TraceData.data
         %      TraceData - Scalar;
         %
         %  To avoid ambiguity with the metadata, two traces are subtracted
         %  by explicitly subtracting the one's data from the other:
         %
         %      % assertCompatibility(TraceData1, TraceData2); % for debug
         %      TraceData1 - TraceData2.data
         %
         % see also testCompatibility, assertCompatibility
         
         if isnumeric(B)
            % A is guaranteed to be a TraceData
            for n = 1:numel(A)
               A(n).data = A(n).data - B; % subtract either a scalar or a COLUMN of numbers (same length as TraceData's data)
            end
         elseif isa(B,'TraceData')
            error('TraceData:minus:ambiguousOperation',...
               ['Subtracting a Trace from a constant is not supported.\n'...
               'For equivalent functionality, add the negative.\nEx.  ans = 5 + (-T)']);
         else
            error('TraceData:minus:unknownClass','do not know how to subtract a %s from a %s', class(B), class(A));
         end
      end
      
      function A = times(A,B)
         % TIMES A .* B elementwise TraceData multiplication
         %   A .* B or B .* A 
         % Either A or B can be a scalar, or a vector of same size as the
         % data elements of the TraceData object.
         %
         %  To avoid ambiguity with the metadata, two traces are multiplied
         %  by explicitly multiplying one's data with the other:
         %
         %      % assertCompatibility(TraceData1, TraceData2); % for debug
         %      TraceData1 .* TraceData2.data
         %
         % see also testCompatibility, assertCompatibility
         if isnumeric(B)
            for n=1:numel(A)
               A(n).data = A(n).data .* B; % B should be either scalar or same size as obj.data
            end
         elseif isnumeric(A)
            [A, B] = deal(B, A); % swap values
            for n=1:numel(A)
               A(n).data = A(n).data .* B; % B should be either scalar or same size as obj.data
            end
         else
            error('TraceData:times:unknownClass','do not know how to multiply a %s with a TraceData object', class(B));
         end
      end
      
      function C = mtimes(A, B)
         % mtimes matrix multiplication A * B
         % result is a matrix, vector, or scalar. (NOT a TraceDataObject)
         if isa(A,'TraceData')
            C = A.data * B;
         else
            C = A * B.data;
         end
      end
      
      function A = rdivide(A, B)
         % rdivide elementwise division A ./ B
         % A must be a TraceData object
         % B can be either a scalar or vector of numbers the same size as A.data
         %
         %  To avoid ambiguity with the metadata, two traces are multiplied
         %  by explicitly dividing one's data from the other:
         %
         %      % assertCompatibility(TraceData1, TraceData2); % for debug
         %      TraceData1 ./ TraceData2.data
         %
         % see also testCompatibility, assertCompatibility
         
         if isnumeric(B)
            % A is guaranteed to be a TraceData
            for n=1:numel(A)
            A(n).data = A(n).data ./ B; % subtract either a scalar or a COLUMN of numbers (same length as TraceData's data)
            end
         else
            error('TraceData:rdivide:unknownClass','do not know how to divide a %s from a TraceData object', class(B));
         end
      end
      
      function A = power(A, B)
         % .^ Array Power
         assert(isa(A,'TraceData'),'TraceData:power:invalidType',...
            'for A .^ B, B cannot be a TraceData object');
         assert(isnumeric(B),'TraceData:power:invalidType',...
            'for A .^ B, B must be numeric');
         for n=1:numel(A)
         A(n).data = A(n).data .^ B; % B should be scalar or same length as A
         end
      end
      
      function A = uminus(A)
         % unary minus (-) for traces
         for n=1:numel(A)
            A(n).data = -A(n).data;
         end
      end
      
      function A = abs(A)
         for n=1:numel(A)
            A(n).data = abs(A(n).data);
            % A(n).units = ['abs (', A(n).units, ')'];
         end
      end
      
      function A = sign(A)
         %sign get signum for data in A
         for n=1:numel(A)
            A(n).data = sign(A(n).data);
            A(n).units = ['sign(', A(n).units, ')'];
         end
      end
               
      %% more complicated 
      function A = diff(A, varargin)
         % FREQUENCY is not considered!
         % otherwise, would be X = diff(X) .* Freq
         if isempty(varargin)
            A.data = diff(A.data) .* A.samplerate;
            A.data = diff(A.data);
         else
            error('not implemented yet');
         end
         for I=1:numel(A)
            tempUnits = A(I).units;
            whereInUnits = strfind(tempUnits,' * sec');
            if isempty(whereInUnits)
               A(I).units = [tempUnits, ' / sec'];
            else
               tempUnits(whereInUnits(1) :whereInUnits(1)+5) = [];
               A(I).units = tempUnits;
            end
         end
      end
      
      function w = integrate (w,method)
         %INTEGRATE integrates a waveform signal
         %   waveform = integrate(waveform, [method])
         %   goes from Acceleration -> Velocity, and from Velocity -> displacement
         %
         %   wave = integrate(waveform)  or
         %   wave = integrate(waveform,'cumsum') performs integration by summing the
         %   data points with the cumsum function, taking into account time interval
         %   and updating the units as appropriate.
         %
         %   waveform = integrate(waveform, 'trapz') as above, but uses matlab's
         %   cumtrapz function to perform the integration.
         
         %   Input Arguments
         %       WAVEFORM: a waveform object   N-DIMENSIONAL
         %       METHOD: either 'cumtrapz' or 'cumsum'  [default is cumsum]
         %
         %   Actual implementation  merely does a cumulative sum of the waveform's
         %   samples, and updates the units accordingly.  These units may be a
         %   little kludgey.
         %
         %
         %   See also CUMSUM, CUMTRAPZ, WAVEFORM/DIFF
         
         Nmax = numel(w);
         allfreq = [w.samplerate];
         
         if ~exist('method','var')
            method = 'cumsum';
         end
         
         switch lower(method)
            case 'cumsum'
               integratefn = str2func('cumsum');
            case 'trapz'
               integratefn = str2func('cumtrapz');
            otherwise
               error('Waveform:integrate:unknownMethod',...
                  'Unknown integration method.  Valid methods are ''cumsum'' and ''trap''');
         end
         
         for I = 1 : Nmax
            w(I).data = integratefn(w(I).data) ./ allfreq(I);
            tempUnits = w(I).units;
            whereInUnits = strfind(tempUnits,' / sec');
            if isempty(whereInUnits)
               w(I).units = [tempUnits, ' * sec'];
            else
               tempUnits(whereInUnits(1) :whereInUnits(1)+5) = [];
               w(I).units = tempUnits;
            end
         end
      end
      
      function A = demean(A)
         for n=1:numel(A);
            A(n) = A(n) - mean(A(n).data);
         end
      end
      
      function A = detrend(A, varargin)
         for n=1:numel(A);
            A(n).data = detrend(A(n).data,varargin{:});
         end
      end
      
      %% extended functionality
      function [A, phi, f] = amplitude_spectrum(td)
         % waveform.amplitude_spectrum Simple method to compute amplitude
         % spectrum for a waveform object. Uses the MATLAB fft function.
         %   [A, phi, f] = amplitude_spectrum(td)
         %
         %   Inputs:
         %       td - a single TraceData object
         %
         %   Outputs:
         %       A - the amplitude coefficients
         %       phi - the phase coefficients
         %       f - the frequency values corresponding to elements of A and phi
         %
         %   Example:
         %       [A phi, f] = amplitude_spectrum(td)
         %       plot(f,A);
         %       xlabel('Frequency (Hz)')
         %       ylabel('Amplitude');
         %
         %   Glenn Thompson, November 21, 2014
         
         N = length(td.data);
         NFFT = 2 ^ nextpow2(N); % Next power of 2 from length of y
         Y = fft(td.data, NFFT); % X will have same length as signal, and will be complex with a magnitude and phase
         A = 2 * abs(Y(1:NFFT/2+1)) / N;
         phi = angle(Y);
         f = td.samplerate / 2 * linspace(0,1,NFFT/2+1);
      end
      
      function obj = clip(obj, vals)
         %CLIP clips a trace's data at a particular max/min value range
         %   clippedtraces = clip(traces, values)
         %
         %   Input Arguments
         %       TRACES: an N-dimensinoal TraceData object
         %       VALUES: a number.  If a scalar, then amplitudes will be
         %           clipped at +/- value.  If a pair, eg. [Max, Min] then
         %           traces will be clipped between these two values
         %
         %   All values beyond maximum ranges will be set to the maximum range
         %
         %
         % See also  despike
         
         if nargin < 2,
            vals = [];
         end
         
         switch numel(vals)
            case 0
               warning('TraceData:clip:noClipValue',...
                  'No values given, TraceData remains unclipped');
               return
               
            case 1 % clip at +/- input value
               if ~isnumeric(vals)
                  error('TraceData:clip:invalidClipValue','Non-numeric clip value');
               end
               vals = abs(vals);
               disp(['Clipping at +/- ' num2str(vals)]);
               vals = [-vals vals];
               
            case 2
               if ~isnumeric(vals)
                  error('TraceData:clip:invalidClipValue','Non-numeric clip value');
               end
               if vals(1) > vals(2)
                  error('TraceData:clip:reversedValues',...
                     'Clipping values are  reversed: Value1 %f > Value2 %f', vals(1),vals(2));
               end
               %everything is AOK
            otherwise
               warning('TraceData:clip:invalidClipValue',...
                  'Invalid clip values. TraceData remains unclipped. specify [min max] values');
               return
         end
         
         for N = 1: numel(obj)
            d = obj(N).data;
            d(d < vals(1)) = vals(1);
            d(d > vals(2)) = vals(2);
            obj(N).data = d;
         end
      end
      
      function d = double(obj,option)
         % double get TraceData data as zero-padded columns
         if nargin == 1
            createDefaultArray = @zeros;
         else
            if ischar(option)
               createDefaultArray = str2func(option);
            elseif isa(option,'function_handle')
               createDefaultArray = option;
            else
               error('waveform:double:invalidOption',...
                  '''option'' must be either a function handle or function name.');
            end
         end
         dlens = arrayfun(@(x) numel(x.data), obj);
         maxlen = max(dlens(:));
         d = createDefaultArray(maxlen,numel(obj));
         for n = 1:numel(obj)
            d(1:numel(obj(n).data),n) = double(obj(n).data);
         end
      end
      
      function tf = eq(A, B)
         tf = all(A.data == B.data) && A.samplerate==B.samplerate && strcmp(A.units, B.units);
      end
      function tf = ne(A,B)
         tf = ~eq(A,B);
      end;
      function outT = extract(Tr, method, starts, ends)
         switch lower(method)
            case 'index'
               assert(numel(starts) == numel(ends));
               outT = repmat(Trace,numel(Tr),numel(starts));
               for n=1:numel(T);
                  for t=1:numel(starts)
                     outT(n,t) = Tr(n);
                  outT(n,t).data = Tr(n).data(starts(t), ends(t));
                  end
               end
         end
      end
      
      function td = fillgaps(td,value, gapvalue)
         % FILLGAPS - fill missing data with values of your choice
         % T = fillgaps(T,number) fills data with the number of your choice
         %   "number" can also be nan or inf or -inf
         %
         % T = fillgaps(T,[]) removes missing data from trace.  Warning, the
         %   resulting timing issues are NOT corrected for!
         %
         % T = fillgaps(T,'method') replaces data using an interpolation method of
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
         % T = fillgaps(T,number, gapvalue), then ALL data points with the value
         % GAPVALUE will be replaced by NUMBER.
         
         if ~(isnumeric(value) && (isscalar(value) || isempty(value)) || ischar(value))
            warning('TraceData:fillgaps:invalidGapValue',...
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
               for N = 1:numel(td);
                  allgaps = getgaps(td(N));
                  % do not include the values to be replaced
                  meanVal = mean(td(N).data(~allgaps));
                  if isnan(meanVal)
                     meanVal = 0;
                  end
                  td(N).data(allgaps) = meanVal;
               end
            case 'number'
               for N = 1:numel(td);
                  td(N).data(getgaps(td(N))) = value;
               end
            case 'interp' % blame Glenn, inspired by http://www.mathworks.com/matlabcentral/fileexchange/8225-naninterp by E Rodriguez
               for N = 1:numel(td);
                  X = td(N).data;
                  X(isnan(X)) = interp1(find(~isnan(X)), X(~isnan(X)), find(isnan(X)),'cubic');
                  td(N).data = X;
               end
            otherwise
               error('TraceData:fillgaps:unimplementedMethod',...
                  'Unimplemented fillgaps method [%s]', fillmethod);
         end
      end
      
      function T = zero2nan(T,mgl)
         %ZERO2NAN: This function takes a waveform with gaps that have been filled
         %   with zeros and converts them to NaN values. This is the inverse of w =
         %   fillgaps(w,0). An input mgl defines the minimum gap length to be
         %   converted to NaN gaps, i.e. if only 5 consecutive zero values exist in
         %   a given small gap, they will be converted to NaN values if mgl <= 5 and
         %   left as zero values if mgl > 5
         %
         %USAGE: w = zero2nan(w,mgl)
         %
         %REQUIRED INPUTS:
         %   w - waveform object with zero-value gaps to be converted to NaN gaps
         %   mgl - minimum gap length (datapoints) to convert to NaN values
         %
         %OUTPUTS: w - waveform with gaps converted to NaN
         
         % Author: Dane Ketner, Alaska Volcano Observatory
         % Modified: Celso Reyes: rewrote algorithm to elimenate looping (2x faster)
         %                        results differ because old method converted
         %                        5 zeros only if mgl <5 (not <=5)
         
         for nw = 1:numel(T)
            closeToZero = abs(T(nw).data) < 0.1; % 0.1 was already chosen -CR
            
            % --- the logic below should be pulled into a new function, since it is
            % shared across a couple different areas, such as waveform/clean -- %
            firstZeros = find(diff([false; closeToZero(:)]) == 1);
            lastZeros = find(diff([closeToZero(:); false]) == -1);
            assert(numel(firstZeros) == numel(lastZeros));
            nContiguousZeros = lastZeros - firstZeros + 1;
            firstZeros(nContiguousZeros < mgl) = [];
            lastZeros(nContiguousZeros < mgl) = [];
            
            for c=1:numel(firstZeros)
               T(nw).data(firstZeros(c) : lastZeros(c)) = NaN;
            end
         end
      end

      function t = fix_data_length(t, maxlen)
         %FIX_DATA_LENGTH adjust length of waveform data to allow batch processing
         %   trace = fix_data_length(traces)
         %       adjusts all traces to the length of the largest, while
         %       zero-padding all shorter traces
         %
         %   trace = fix_data_length(traces, maxlength)
         %       sets all data lengths to maxlength, padding with zero or
         %       truncating as necessary.
         %
         %  examples
         %       % let traces be a 1x2 TraceData object
         %       % 3000 samples in traces(1)
         %       % 10025 samples in traces(2)
         %
         %       % set both waves' data to a length of to 10025 while padding the
         %       % smaller of the two with zeroes.
         %       outTraces = fix_data_length(traces)
         %
         %       % set both sample lengths to 500 truncating both of them...
         %       outTraces = fix_data_length(traces, 500)
         datalengths = arrayfun(@(x) numel(x.data), t);
         if ~exist('maxlen','var')
            maxlen = max(datalengths);
         end
         
         for n=find(datalengths < maxlen)
            t(n).data(maxlen) = 0;
         end
         
         for n=find(datalengths > maxlen);
            t(n).data = t(n).data(1:maxlen);
         end
      end

      function T = hilbert(T, n)
         %HILBERT (for WAVEFORM objects) Discrete-time analytic Hilbert transform.
         %   waveform = hilbert(waveform)
         %   waveform = hilbert(waveform, N);
         %
         % THIS version only returns the abs value in the waveform.  If you want to
         % keep the imaginary values, then you should use the built-in hilbert
         % transform.  ie.  Don't feed it a trace, feed it a vector... - CR
         %
         %
         % See also FFT, IFFT, for details and the meaning of "N" see HILBERT
         
         if nargin==2
            T = arrayfun(@myHilbertN,T);
         else
            T = arrayfun(@myHilbert,T);
         end
         
         function Tr = myHilbert(Tr)
            Tr.data = abs(hilbert(Tr.data));
            Tr.units = 'abs(hilbert)';
         end
         
         function Tr = myHilbertN(Tr)
            Tr.data = abs(hilbert(Tr.data, n));
            Tr.units = 'abs(hilbert)';
         end
      end
      
      function T = resample(T, method, crunchFactor)
         %RESAMPLE resamples a waveform at over every specified interval
         %   w = resample(waveform, method, crunchfactor)
         %
         %   Input Arguments
         %       WAVEFORM: waveform object       N-dimensional
         %
         %       METHOD: which method of sampling to perform within each sample
         %                window
         %           'max' : maximum value
         %           'min' : minimum value
         %           'mean': average value
         %           'median' : mean value
         %           'rms' : rms value (added 2011/06/01)
         %           'absmax': absolute maximum value (greatest deviation from zero)
         %           'absmin': absolute minimum value (smallest deviation from zero)
         %           'absmean' : mean deviation from zero (added 2011/06/01)
         %           'absmedian' : median deviation from zero (added 2011/06/01)
         %           'builtin': Use MATLAB's built in resample routine
         %
         %       CRUNCHFACTOR : the number of samples making up the sample window
         %
         % For example, resample(T,'max',5) would grab the max value of every 5
         % samples and return that in a waveform of adjusted frequency.  as a
         % result, the waveform will have 1/5 of the samples
         %
         %
         % To use matlab's built-in RESAMPLE method...
         %       % assume T is an existing waveform
         %       D = double(T);
         %       ResampleD = resample(D,P,Q);  % see matlab's RESAMPLE for specifics
         %
         %       %put back into waveform, but don't forget to update the frequency
         %       T.data = ResampleD; 
         %       T.samplerate = NewFrequency;
         %
         % See also RESAMPLE, MIN, MAX, MEAN, MEDIAN.
         
         % AUTHOR: Celso Reyes (celso@gi.alaska.edu)
         % 10/2015: Celso Reyes: put in TraceData and restructured
         % 7/6/2011: Glenn Thompson: Made all methods NaN tolerant (replace max with nanmax etc) - checks for statistics toolbox
         % 6/1/2011: Glenn Thompson: Added methods for ABSMEAN, ABSMEDIAN and RMS
         
         persistent STATS_INSTALLED;
         if isempty(STATS_INSTALLED)
            STATS_INSTALLED = ~isempty(ver('stats'));
         end
         
         if ~(round(crunchFactor) == crunchFactor)
            disp ('val needs to be an integer');
            return;
         end;
         method = lower(method);
         
         % determine which function to use on the data.  This will
         % automatically determine whether it can use the NaN-safe version
         if ~strcmp(method,'builtin')
            if STATS_INSTALLED
               if numel(method) > 3 && strcmpi(method(1:3),'ABS')
                  methodfn = str2func(['nan' method(4:end)]);
               else
               methodfn = str2func(['nan', method]);
               end
            else
               if numel(method) > 3 && strcmpi(method(1:3),'ABS')
                  methodfn = str2func(method(4:end));
               else
                  methodfn = str2func(method);
               end
            end
         end
         
         for i=1:numel(T)
            nRows = ceil(length(T(i).data) / crunchFactor);
            totVals = nRows * crunchFactor; % total number of values that can be accomodated
            if length(T(i).data) < totVals
               T(i).data(end+1:totVals) = mean(T(i).data((nRows-1)*totVals : end)); %pad it with the avg value
            end;
            
            d = reshape(T(i).data,crunchFactor,nRows); % produces ( val x rowcount) matrix
            switch upper(method)
               case {'MAX', 'MIN', 'RMS'}
                  T(i).data = methodfn(d, [], 1);
               case {'MEAN', 'MEDIAN'}
                  T(i).data = methodfn(d, 1);
               case {'ABSMAX', 'ABSMIN'}
                  T(i).data = methodfn(abs(d),[],1);
               case {'ABSMEAN', 'ABSMEDIAN'}
                  T(i).data = methodfn(abs(d), 1);
               case 'BUILTIN'
                  % assume T is an existing trace
                  ResampleD = resample(T(i).data,1,crunchFactor);  % see matlab's RESAMPLE for specifics
                  T(i).data = ResampleD(:);
               otherwise
                  error('TraceData:resample:UnknownSampleMethod',...
                     'Don''t know what you mean by resample via %s', method);
            end;
            T(i).samplerate = T(i).samplerate ./ crunchFactor;
         end
      end
      
      function A = smooth(A, varargin)
         % smooth requires the signal fitting toolbox
         % see smooth
         for n = 1:numel(A)
            A(n).data = smooth(A(n).data,varargin{:});
         end
      end
      
      function T = taper(T, R, style)
         % trace = TAPER(trace,R) applies a cosine taper to the ends of a
         % trace where r is the ratio of tapered to constant sections and is between
         % 0 and 1. For example, if R = 0.1 then the taper at each end of the trace
         % is 5% of the total trace length. R can be either a scalar or the same
         % size as TRACE. If R is a scalar, it is applied uniformly to each
         % waveform. Note that if R is set to 1 the resulting taper is a hanning
         % window.
         %
         % trace = TAPER(trace) same as above with a default taper of R = 0.2.
         %
         % TODO: Currently, only cosine tapers are supported. The code is set up to
         % accept other window shapes as a final argument, e.g.
         % taper(trace,R,'cosine'). However other window shapes have not yet been
         % implimented. - MEW
         
         % AUTHOR: Michael West
         % Modified: Celso Reyes
         
                  
         if ~exist('R','var') || isempty(R)
            R = 0.2; %assign default taper
         elseif ~isnumeric(R)
            error('TraceData:taper:InvalidRValue',...
               'R, if specified, must be numeric');
         end
         
         if ~exist('style','var') || isempty(style)
            style = 'COSINE';
         end
         
         
         if isscalar(R)
            R = repmat(R,size(T));
         end
         
         if (isvector(R) && isvector(T)) && numel(R) == numel(T)
            if all(size(T)) ~= size(R)
               % same number of elements, but R is Nx1 and w is 1xN or vice-versa
               warning('TraceData:taper:columnsVsRows',...
                  ['One input (either R or the wavform) is arranged in '...
                  'columns while the other is arranged in Rows.  While they '...
                  'should be the same shape, taper is continuing with R''']);
               R = R';
            end
         end
         
         if ~all(size(T) == size(R))
            error('TraceData:taper:InvalidRSize',...
               'R must either be a scalar value, or must be the same size as the input waveforms');
         end
         
         switch upper(style)
            case 'COSINE'
               for n=1:numel(T)
                  T(n) = docosine(T(n),R(n));
               end
            case 'GAUSSIAN'
               %not implemented, placeholder only.
               error('TraceData:taper:invalidTaperType',...
                  'Gaussian taper is not yet implimented');
            otherwise
               error('TraceData:taper:invalidTaperType',...
                  'This style of taper is not recognized.');
         end;
         
         function T = docosine(T,r)
            %applied to individual traces only
            T = T .* tukeywin( numel(T.data) , r );
         end
      end

      function [tf, msg] = testCompatibility(A, B)
         % testCompatibility confirms matching units, samplerate, and data length
         % tf = testCompatibility(A, B) will make sure that A and B have
         % matching units, sample frequencies, and data length.  
         % If units are empty for either A or B, then units will pass
         % If samplerate is empty for either A or B, then samplerate will
         % pass.  samplerate is compared within a tolerance of 10e-2
         %
         % [tf, msg] = testCompatibility(A,B) will also return a message
         % describing how the test failed.
         %
         % sample usage: 
         %   % assume A & B are TraceData
         %   if testCompatibility(A,B)
         %     dosomething(A, B)
         %   end
         %
         % see also assertCompatibility
         TOL = 10e-2;
         if ~(numel(A.data) == numel(B.data))
            tf = false;
            msg = 'Data lengths do not match';
         elseif ~(isempty(B.units) ||isempty(A.units) || strcmp(A.units, B.units))
            tf = false;
            msg = sprintf('Units do not match [%s] vs [%s]', A.units, B.units);
         elseif ~(isempty(A.samplerate) || isempty(B.samplerate) || isnan(A.samplerate) || isnan(B.samplerate) || ismembertol(A.samplerate,B.samplerate, TOL))
            tf = false;
            msg = sprintf('Frequencies do not match [%f] vs [%f]',A.samplerate, B.samplerate);
         else
            tf = true;
            msg = '';
         end
      end
      
      function assertCompatibility(A, B)
         % assertCompatibility asserts matching units, samplerate, and data length
         % assertCompatibility(A, B) will error unless A and B have
         % matching units, sample frequencies, and data length.  The error
         % message will describe what is wrong
         %
         % use this within a try-catch, or when debugging
         %
         % sample debugging usage: 
         %   % assume A & B are TraceData
         %   assertCompatibility(A,B)
         %   C = A + B.data;
         %
         % sample prduction usage:
         %   try
         %     assertCompatibility(A,B)
         %     C = A + B.data;
         %   catch er
         %     % handle this failure somehow
         %   end
         %
         % see also testCompatibility
         [tf, msg] = testCompatibility(A, B);
         assert(tf, 'TraceData:compatabilityCheckFailed', msg);
      end
      
      %% stacking functions
      function out = stack(T)
         %STACK stacks data from array of waveforms
         %   StackedWave = stack(waveforms)
         %   ASSUMES frequencies are the same. data does not need to be the same
         %   length, but shorter waveforms will be padded with zeros at the end
         %   prior to stacking.
         %
         %   Stacks all waves, regardless of waveform's dimension
         %
         %   Data is summed, but the average is not taken, nor is it normalized. You
         %   may wish to change the station and/or channel names to reflect the
         %   properties of this waveform.  Possibly change the units, also, if that
         %   makes sense.
         %
         %   Output retains the same info as the very first waveform (minus history)
         %   the station name becomes the original name with "- stack (N)" tacked onto
         %   the end.
         %
         %   To ensure frequency and time matching, use ALIGN
         %
         %   See also WAVEFORM/ALIGN
         
         out = T(1);
         out.station = [out.station ' - stack (' num2str(T) ')'];
         out.data = sum(double(T),2);
      end
      function stk = bin_stack(T,bin,ovr)
         %BIN_STACK: Stack input waveforms with N waveforms per stack. The number N
         %    is specified by input 'bin'. The input 'ovr' specifies the amount of
         %    overlap between bins.
         %
         %USAGE: stk = bin_stack(w,bin,ovr)
         %    If input w contains 100 waveforms then:
         %    stk = bin_stack(w,20,0) % stk has 5 stacks of 20 waveforms
         %    stk = bin_stack(w,5,0)  % stk has 20 stacks of 5 waveforms
         %    stk = bin_stack(w,20,10)  % stk has 9 stacks of 20 waveforms
         %
         %INPUTS:  w   - Input waveform
         %         bin - Bin size of stacked waveforms
         %         ovr - Number of overlapping events between bins
         %
         %OUTPUTS: stk - Array of stacked waveforms
         
         % Author: Dane Ketner, Alaska Volcano Observatory
         
         nw = numel(T);
         inc = bin-ovr;
         n=1;
         while 1
            if (n-1)*inc+bin > nw
               return
            else
               stk(n) = stack(T((n-1)*inc+1:(n-1)*inc+bin));
               n=n+1;
            end
         end
      end
   end
   
   %% protected methods
   methods(Access=protected)
      %none
   end
   
   methods(Static)
      function set_parameter(name, val)
         % set_parameter changes state behavior for the TraceData objects
         %
         %     TRUST_ASSIGNMENTS
         %     set_parameter('trust_assignments', true) will verify the
         %     shapes and types of each calculation before storing the data
         %     in the object
         %     set_parameter('trust_assignments', false) will not perform
         %     size/class checks. Use this only when you are looking for
         %     extra speed and tightly control the inputs to this class.
         %
         %     DEBUG_LEVEL
         %
         disp(val)
         disp('not active yet');
         switch lower(name)
            case 'trust_assignments'
               % set the parameter trust_assignments to logical(val);
            case 'debug_level'
               % set the parameter debug_level to numerical val
            otherwise
         end
      end
            
   end
   
end

