classdef TraceData
   %TraceData   Handles the data associated with timeseries.
   %
   %   TraceData contains the functionality associated with data
   %   manipulation, including dealing with units.
   %
   %   TraceData might be considered a "light" version of MATLAB's timeseries
   %   class. Whereas the timeseries class has lots of functionality, it
   %   suffers (at the time of this writing) from much slower execution times.
   %
   % About TraceData vs waveform
   %
   % TraceData Properties:
   %       data       - column of evenly sampled data
   %       samplerate - number of samples per second
   %       units      - units for the data, ex. 'counts', 'm / sec'
   %       duration   - time between first and last samples
   %       hasnan     - true if any value is nan
   %
   % TraceData Methods:
   %
   %    Derived properties:
   %       nyquist - Nyquist frequency (samplerate / 2)
   %       period - Period  (1/samplerate)
   %       formattedduration - retrieve duration as formatted text
   %
   %    additional Methods:
   %       nsamples  - return number of data samples
   %    Mathamatical operations:
   %       plus - (+)addition
   %       minus - (-)subtraction
   %       times - (.*) element multiplication
   %       mtimes - (*) matrix multiplication
   %       rdivide - (./) element division
   %
   %       uminus - (-A) unary minus
   %       sign - signum of data (returns array of +1, 0, or -1)
   %       abs - Absolute value
   %
   %    Binary Operators:
   %       eq - (A==B) true if data, samplerate and units match.
   %       ne - (A~=B) false if data, samplerate and units match.
   %
   %    Statistics (returns a single value for each trace):
   %       min - Minimum value of data
   %       max - Maximum  value of data
   %       mean - Average value of data
   %       median - Median value of data
   %       var - Variance of data
   %       std - Standard Deviation of data
   %
   %    Advance Mathamatical operations:
   %       diff - Difference and approximate derivative for traces
   %       integrate - cumulative sums of data
   %
   %       hilbert - Hilbert envelope (real only)
   %       taper - Apply a taper to the data
   %       resample - Resample the data
   %       demean - Remove the mean
   %       detrend - Remove trend from data
   %       clip - Clip the data
   %
   %       extract - Retrieve a subset of the data
   %
   %    Conversion operations:
   %       double - retrieve data as 1xN array of double
   %
   %       stack - stack all waveforms
   %       binStack - stack N waveforms at a time (with optional overlap)
   %
   %       compatibleWith - Compare units, samplerate and datalength
   %       assertCompatibleWith - Error if units, samplerate and datalength do not match
   %
   %       fillgaps - replace nan values (can replace other values)
   %       zero2nan - Replace values close to zero with nans
   %       amplitude_spectrum
   %       setlength - adjust length of data to allow batch processing
   %
   % See also Seismictrace, waveform, timeseries
   
   
   % Error recovery and trapping with traces
   % trying new tactic. I won't try to anticipate all the various ways
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
   %  - additinal not-so-sure-we-need-these functions
   %    : getpeaks
   
   properties
      data = []% time-series data, kept in a column
      samplerate  = NaN % in samples/sec
      units = 'none' % text description of data units
   end
   
   properties(Dependent)
      duration % duration in seconds. To get matlab duration, divide by 86400
      hasnan;
   end
   
   properties(Hidden=true)
      % when trust_assignments is false, then data
      trust_assignments = false; % if not trusted, then slows down computations somewhat, but is useful for debugging.
      debug_level
   end
   
   methods
      function obj = TraceData(varargin)
         %TraceData construct a TraceData object
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
      
      function tf = get.hasnan(obj)
         %get.hasnan   functional hasnan allows for
         % NOTE: technically, hasnan could be set as data is entered.
         %   any([T.hasnan])
         tf = any(isnan(obj.data));
      end
      function obj = set.data(obj, values)
         %set.data   Assign values to data as a column
         obj.data = values(:);
      end
      
      
      function N = nyquist(T)
         %nyquist   the nyquist frequency calculated as (samplerate / 2)
         N=[T.samplerate] ./ 2;
         reshape(N,size(T));
      end
      
      function p = period(T)
         %period   Period, calculated as (1 / samplerate)
         p = 1 ./ [T.samplerate];
         % NOT reshaped
      end
      
      function val = sampletimes(obj)
         %sampletimes  MATLAB time offset of each sample.
         %
         % equivalent to waveform's get(w,'timevector');
         assert(numel(obj) == 1, 'only works on one TraceData at a time');
         val = (0:(numel(obj.data)-1)) .* obj.period / 86400;
         val = val(:);
      end
      
      function secondsOfData = get.duration(obj)
         %secondsOfData   Duration of samples, in seconds
         if isempty(obj.data) || isempty(obj.samplerate)
            secondsOfData = 0;
         else
            secondsOfData = numel(obj.data) / obj.samplerate;
         end
      end
      
      function n = nsamples(obj)
         %nsamples   number of samples in the trace(s)
         %   n = nsamples(traces) will return the number of samples for
         %   each trace in an array of the same size as traces
         %
         %   See also numel
         n = zeros(size(obj));
         for m=1:numel(obj)
            n(m) = numel(obj(m).data);
         end
      end
            
      
      function s = formattedduration(obj, fmt)
         %formattedduration   Duration as a formatted string
         %  s = trace.formattedduration() retrieves the duration in the
         %  default format as 'dd:hh:mm:ss.SSS'
         %  s = trace.formattedduration(fmt) retrieves duration in format
         %  specified.
         %
         %  depends upon the duration class, introduced in r2014b
         %
         %  See also duration
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
         %+   Plus.
         %   C=A+B add something to the TraceData's data.
         %
         %   valid combinations
         %      TraceData + NumericVector; % same length as TraceData.data
         %      TraceData + Scalar;
         %
         %  To avoid ambiguity with the metadata, two traces are added
         %  together by explicitly adding the data from one to the other:
         %
         %      % assertCompatiblewith(TraceData1, TraceData2); % for debug
         %      TraceData1 + TraceData2.data
         %
         % See also compatiblewith, assertCompatiblewith
         
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
               ' metadata you wish to keep.\nEx. T = T1 + T2.data']);
         else
            error('TraceData:plus:unknownClass','do not know how to add a %s to a TraceData object', class(B));
         end
      end
      
      function A = minus(A, B)
         %-  Subtract something from the Trace's data,
         %   C=A-B This will return a TraceData object
         %
         %   valid combinations
         %      TraceData - NumericVector; % same length as TraceData.data
         %      TraceData - Scalar;
         %
         %   To avoid ambiguity with the metadata, two traces are subtracted
         %   by explicitly subtracting the one's data from the other:
         %
         %      % assertCompatiblewith(TraceData1, TraceData2); % for debug
         %      TraceData1 - TraceData2.data
         %
         %   See also compatiblewith, assertCompatiblewith
         
         if isnumeric(B)
            % A is guaranteed to be a TraceData
            for n = 1:numel(A)
               A(n).data = A(n).data - B; % subtract either a scalar or a COLUMN of numbers (same length as TraceData's data)
            end
         elseif isa(B,'TraceData')
            error('TraceData:minus:ambiguousOperation',...
               ['Subtracting a Trace from a constant is not supported.\n'...
               'For equivalent functionality, add the negative.\nEx. ans = 5 + (-T)']);
         else
            error('TraceData:minus:unknownClass','do not know how to subtract a %s from a %s', class(B), class(A));
         end
      end
      
      function A = times(A,B)
         %.*   Elementwise Trace data multiplication
         %   C=A.*B or C=B.*A when A is a TraceData object
         %   Either A or B can be a scalar, or a vector of same size as the
         %   data elements of the TraceData object.
         %
         %   To avoid ambiguity with the metadata, two traces are multiplied
         %   by explicitly multiplying one's data with the other:
         %
         %      % assertCompatiblewith(TraceData1, TraceData2); % for debug
         %      TraceData1 .* TraceData2.data
         %
         %  See also compatiblewith, assertCompatiblewith
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
         %*   Matrix multiplication against data within a trace
         %   C=A*B matrix multiplication against data within a trace
         %   result is a matrix, vector, or scalar. (NOT a TraceDataObject)
         
         if isa(A,'TraceData')
            C = A.data * B;
         else
            C = A * B.data;
         end
      end
      
      function A = rdivide(A, B)
         %./  Divide data elements of A by B
         %   C=A./B performs elementwise division on trace data
         %   A must be a TraceData object
         %   B can be either a scalar or vector of numbers the same size as A.data
         %
         %   To avoid ambiguity with the metadata, two traces are multiplied
         %   by explicitly dividing one's data from the other:
         %
         %   % assertCompatiblewith(TraceData1, TraceData2); % for debug
         %   TraceData1 ./ TraceData2.data
         %
         %   See also times, mtimes, compatiblewith, assertCompatiblewith
         
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
         %.^   Array power for TraceData
         %   C=A.^B raises each data element of A to the power B and then
         %   returns the resulting trace(s)
         %
         %   See also power
         
         assert(isa(A,'TraceData'),'TraceData:power:invalidType',...
            'for A .^ B, B cannot be a TraceData object');
         assert(isnumeric(B),'TraceData:power:invalidType',...
            'for A .^ B, B must be numeric');
         for n=1:numel(A)
            A(n).data = A(n).data .^ B; % B should be scalar or same length as A
         end
      end
      
      function A = uminus(A)
         %-   Unary minus.
         %   -A negates the data in A and returns the resulting trace(s)
         %
         %   see also uminus
         for n=1:numel(A)
            A(n).data = -A(n).data;
         end
      end
      
      function trace = abs(trace)
         %Absolute value of trace data
         %  T = abs(trace) returns traces containing the absolute values of
         %  the data.
         %
         %See also abs, sign
         for n=1:numel(trace)
            trace(n).data = abs(trace(n).data);
         end
      end
      
      function trace = sign(trace)
         %sign   Convert each data point to its signum (+1, 0, +1)
         % T = sign(trace) returns a a trace containing the signs of the
         % data, instead of the data.
         %
         % See also sign
         for n=1:numel(trace)
            trace(n).data = sign(trace(n).data);
            %trace(n).units = ['sign(', trace(n).units, ')'];
         end
      end
      
      %% more complicated
      function T = diff(T, varargin)
         %diff   Difference and approximate derivative for traces
         %  A = diff(trace)
         %  A = diff(trace, options) see the builtin diff for details on
         %  available options.
         %
         %  trace must have samplerate and data assigned, otherwise you may
         %  get "a Matrix dimensions must agree" error
         %
         %  units are automatically changed. Assuming the sample rate is
         %  samples/sec, then the new trace is in currentunits / sec.
         %
         %  See also diff
         if isempty(varargin)
            for I=1:numel(T)
               T(I).data = diff(T(I).data) .* T(I).samplerate; % must have data and sample rate
            end
         else
            error('not implemented yet');
         end
         for I=1:numel(T)
            tempUnits = T(I).units;
            whereInUnits = strfind(tempUnits,' * sec');
            if isempty(whereInUnits)
               T(I).units = [tempUnits, ' / sec'];
            else
               tempUnits(whereInUnits(1) :whereInUnits(1)+5) = [];
               T(I).units = tempUnits;
            end
         end
      end
      
      function T = integrate (T,method)
         %integrate   Integrate a tracedata signal
         %   trace = trace.integrate([method])
         %   goes from Acceleration -> Velocity, and from Velocity -> displacement
         %
         %   tr = trace.integrate()
         %   tr = integrate(trace,'cumsum') performs integration by summing the
         %   data points with the cumsum function, taking into account time interval
         %   and updating the units as appropriate.
         %
         %   tr = trace.integrate('trapz') as above, but uses matlab's
         %   cumtrapz function to perform the integration.
         %
         %   Input Arguments
         %       trace: tracedata   N-DIMENSIONAL
         %       METHOD: either 'cumtrapz' or 'cumsum'  [default is cumsum]
         %
         %   Actual implementation  merely does a cumulative sum of the trace's
         %   samples, and updates the units accordingly. These units may be a
         %   little kludgey.
         %
         %   See also cumsum, cumtrapz, diff
         
         Nmax = numel(T);
         allfreq = [T.samplerate];
         
         if ~exist('method','var')
            method = 'cumsum';
         end
         
         switch lower(method)
            case 'cumsum'
               integratefn = str2func('cumsum');
            case 'trapz'
               integratefn = str2func('cumtrapz');
            otherwise
               error('TraceData:integrate:unknownMethod',...
                  'Unknown integration method. Valid methods are ''cumsum'' and ''trap''');
         end
         
         for I = 1 : Nmax
            T(I).data = integratefn(T(I).data) ./ allfreq(I);
            tempUnits = T(I).units;
            whereInUnits = strfind(tempUnits,' / sec');
            if isempty(whereInUnits)
               T(I).units = [tempUnits, ' * sec'];
            else
               tempUnits(whereInUnits(1) :whereInUnits(1)+5) = [];
               T(I).units = tempUnits;
            end
         end
      end
      
      function A = demean(A)
         %demean   Remove the average from TraceData
         %   A = demean(A) will subtract the mean of a trace from its data.
         %
         %   See also demean
         for n=1:numel(A);
            A(n) = A(n) - mean(A(n).data(~isnan(A(n).data)));
         end
      end
      
      function A = detrend(A, varargin)
         %detrend   Remove the trend from TraceData
         %   A = detrend(A) will subtract the trend of a trace from its
         %   data.  
         %   A = detrand(A, ...) allows for additional options.  For an
         %   explanation of these, see MATLAB's builtin detrend.
         %
         %   See also detrend
         for n=1:numel(A);
            A(n).data = detrend(A(n).data,varargin{:});
         end
      end
      
      function val = bulkCalculate(T, F)
         %bulkCalculate   Run a function against the data
         %  vals = T.bulkCalculate(funcHandle) will against the data field
         %  of each element in T shape is preserved, and all empty
         %  traces return nan FH must return a single value
         %
         %  basically, this will run:
         %    funcHandle(T.data)
         %
         %  for each trace in T
         %
         %  See also max, min, mean, median
         
         val = nan(size(T));
         for n=numel(T) : -1 : 1
            hasdata(n) = ~isempty(T(n).data);
         end
         val(hasdata) = arrayfun(F,T(hasdata));
      end
      function val = max(T)
         %max   Maximum value for trace data
         %   maxVals = max(traces);
         %
         %   See also max
         F = @(X) max(X.data);
         val = T.bulkCalculate(F);
      end
      function val = min(T)
         %min   Minimum value for trace data
         %   minVals = min(traces);
         %
         %   See also min
         F = @(X) min(X.data);
         val = T.bulkCalculate(F);
      end
      function val = mean(T)
         %mean   Average or mean value for trace data
         %   meanVals = mean(traces);
         %
         %   See also mean
         F = @(X) mean(X.data(~isnan(X.data)));
         val = T.bulkCalculate(F);
      end
      function val = median(T)
         %median   Median value for trace data
         %   medianVals = median(traces);
         %
         %   See also median
         F = @(X) median(X.data(~isnan(X.data)));
         val = T.bulkCalculate(F);
      end
      function val = std(T, varargin)
         %std   standard deviation for traces
         %  vals = std(traces) retrieves the std from each trace, returning
         %  a traces array of the same shape as T.
         %  vals = std(traces, options); lets you declare options as per the
         %  builtin version of std
         %  useful option:
         %
         %     vals = T.std('omitnan') % or 'includenan'
         %
         %  See also std, bulkCalculate
         if exist('varargin','var')
            F = @(X) std(X.data,varargin{:});
         else
            F = @(X) std(X.data);
         end
         val = T.bulkCalculate(F);
      end
      function val = var(T, varargin)
         %var   calulate variance for traces
         %  vals = var(traces);
         %  vals = var(traces,options); lets you declare options as per the
         %  builtin version of var.
         %  useful option:
         %    vals = traces.var(taces,'omitnan') % or 'includenan'
         %
         %  See also var, bulkCalculate
         if exist('varargin','var')
            F = @(X) var(X.data,varargin{:});
         else
            F = @(X) var(X.data);
         end
         val = T.bulkCalculate(F);
      end
      %% extended functionality
      [A, phi, f] = amplitude_spectrum(td)
      
      function obj = clip(obj, vals)
         %clip   clips a trace's data at a particular max/min value range
         %   clippedtraces = clip(traces, values)
         %
         %   Input Arguments
         %       TRACES: an N-dimensional TraceData object
         %       VALUES: a number. If a scalar, then amplitudes will be
         %           clipped at +/- value. If a pair, eg. [Max, Min] then
         %           traces will be clipped between these two values
         %
         %   All values beyond maximum ranges will be set to the maximum range
         
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
         %double   TraceData data as double
         %   d = double(T) returns the data within T as a column. If T is
         %   an array with N elements, then data is returned in array with
         %   size N x maximum_data_length_in_T.
         %
         %   d = double(T, fillfunction) allows you to specify how the array
         %   is filled. FILLFUNCTION is a handle or name of any function
         %   that can accept (row, col) arguments, and return an array of some
         %   value. By default, the array is filled with zeros.
         %
         %   Example. Retrieve array using nan as filler
         %   d = double(T, @nan);
         %
         %   See also zeros, nan
         
         if nargin == 1
            createDefaultArray = @zeros;
         else
            if ischar(option)
               createDefaultArray = str2func(option);
            elseif isa(option,'function_handle')
               createDefaultArray = option;
            else
               error('TraceData:double:invalidOption',...
                  '''option'' must be either a function handle or function name.');
            end
         end
         dlens = obj.nsamples();
         maxlen = max(dlens(:));
         d = createDefaultArray(maxlen, numel(obj));
         for n = 1:numel(obj)
            d(1:dlens(n),n) = double(obj(n).data);
         end
      end
      
      function tf = eq(A, B)
         %== Equal for TraceData
         %  eq(A,B) is called for A==B when A or B is a TraceData object.
         %  will return equal if the data , samplerate, and units match.
         %
         %  See also ne
         tf = all(A.data == B.data) && A.samplerate==B.samplerate && strcmp(A.units, B.units);
      end
      
      function tf = ne(A,B)
         %~=   Not equal for TraceData.
         %  A~=B compares the data, samplerate, and units
         %
         %  C = ne(A,B) is called for the syntax 'A ~= B' when A or B is a
         %  TraceData object.
         %  See also eq
         tf = ~eq(A,B);
      end;
      
      function outT = extract(Tr, method, startPos, endPos)
         %extract   Retrieve subset of TraceData
         %
         %    subTraces = extract(traces, 'index', startPos, endPos)
         %
         %
         %   waveform = T.extract('INDEX', startPos, endPos)
         %       returns traces with the subset of data from startIndex to
         %       endIndex.  Essentially, this is equivelent to 
         %       T.data = T.data(startPos, endPos)
         %
         %       data into an array, as in D = get(W,'data'), then returning a
         %       waveform with the subset of data,
         %       ie. waveform = set(waveform,'data', D(startIndex:endIndex));
         %
         %    See also SeismicTrace/extract
         switch lower(method)
            case 'index'
               assert(numel(startPos) == numel(endPos), 'number of start and end indices must match');
               outT = repmat(TraceData,numel(Tr),numel(startPos));
               for n=1:numel(T);
                  for t=1:numel(startPos)
                     outT(n,t) = Tr(n);
                     outT(n,t).data = Tr(n).data(startPos(t), endPos(t));
                  end
               end
         end
      end
      
      function td = fillgaps(td,value, gapvalue)
         %fillgaps   fill missing data with values of your choice
         %  T = T.fillgaps(value) fills data with the number of your choice
         %  VALUE can also be nan or inf or -inf
         %
         %  T = T.fillgaps([]) removes missing data from trace. Warning, the
         %  resulting timing issues are NOT corrected for!
         %
         %  T = T.fillgaps('method') replaces data using an interpolation method of
         %  your choice. Valid methods are:
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
         %  FILLGAPS is designed to replace NaN values. However, if if you
         %  use T = T.fillgaps(number, gapvalue), then ALL data points with
         %  the value GAPVALUE will be replaced by NUMBER.
         
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
         %zero2nan   replaces zeros with nan values.
         % Should be replaced with T.fillgaps(nan, 0)
         % however, it was designed to have a minimum gap length Perhaps this
         % should be added to fillgaps
         %
         %This function replaces gaps that have been filled with zeros and
         %converts them to NaN values. This is the inverse of T =
         %T.fillgaps(0). An input mgl defines the minimum gap length to be
         %converted to NaN gaps, i.e. if only 5 consecutive zero values
         %exist in a given small gap, they will be converted to NaN values
         %if mgl <= 5 and left as zero values if mgl > 5
         %
         %USAGE: T = T.zero2nan(mgl)
         %
         %REQUIRED INPUTS:
         %   mgl - minimum gap length (datapoints) to convert to NaN values
         %
         %OUTPUTS: w - trace with gaps converted to NaN
         %
         %See also nan, fillgaps
         
         % Author: Dane Ketner, Alaska Volcano Observatory
         % Modified: Celso Reyes: rewrote algorithm to elimenate looping (2x faster)
         %                        results differ because old method converted
         %                        5 zeros only if mgl <5 (not <=5)
         
         for nw = 1:numel(T)
            closeToZero = abs(T(nw).data) < 0.1; % 0.1 was already chosen -CR
            
            % --- the logic below should be pulled into a new function, since it is
            % shared across a couple different areas, such as trace/clean -- %
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
      
      function t = setlength(t, maxlen)
         %setlength   adjust length of trace data to allow batch processing
         %   trace = traces.setlength()
         %       adjusts all traces to the length of the largest, while
         %       zero-padding all shorter traces
         %
         %   trace = traces.setlength(maxlength)
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
         %       outTraces = traces.setlength
         %
         %       % set both sample lengths to 500 truncating both of them...
         %       outTraces = traces.setlength(500)
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
         %hilbert   Discrete-time analytic Hilbert transform for traces.
         %   trace = trace.hilbert()
         %   trace = trace.hilbert(N);
         %
         % THIS version only returns the abs value in the trace. If you
         % want to keep the imaginary values, then you should use the
         % built-in hilbert transform. ie. Don't feed it a trace, feed it
         % a vector... - CR
         %
         % See also FFT, IFFT, HILBERT
         
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
         %resample   Resample a trace over a specified interval
         %   T = trace.resample(method, crunchfactor)
         %
         %   Input Arguments
         %       Trace: TraceData or Trace       N-dimensional
         %
         %       METHOD: which method of sampling to perform within each sample
         %                window
         %           'max' : maximum value
         %           'min' : minimum value
         %           'mean': average value
         %           'median' : median value
         %           'rms' : rms value (added 2011/06/01)
         %           'absmax': absolute maximum value (greatest deviation from zero)
         %           'absmin': absolute minimum value (smallest deviation from zero)
         %           'absmean' : mean deviation from zero (added 2011/06/01)
         %           'absmedian' : median deviation from zero (added 2011/06/01)
         %           'builtin': Use MATLAB's built in resample routine
         %
         %       CRUNCHFACTOR : the number of samples making up the sample window
         %
         % For example, T.resample('max',5) would grab the max value of every 5
         % samples and return that in a trace with an adjusted frequency. as a
         % result, the trace will have 1/5 of the samples
         %
         %
         % To use matlab's built-in RESAMPLE method...
         %       % assume T is an existing trace
         %       D = double(T);
         %       ResampleD = D.resample(P,Q);  % see matlab's RESAMPLE for specifics
         %
         %       %put back into trace, but don't forget to update the frequency
         %       T.data = ResampleD;
         %       T.samplerate = NewFrequency;
         %
         % See also RESAMPLE, MIN, MAX, MEAN, MEDIAN.
         
         % AUTHOR: Celso Reyes, Glenn Thompson
         
         persistent STATS_INSTALLED;
         if isempty(STATS_INSTALLED)
            STATS_INSTALLED = ~isempty(ver('stats'));
         end
         
         if ~(round(crunchFactor) == crunchFactor)
            disp ('val needs to be an integer');
            return;
         end;
         method = lower(method);
         
         % determine which function to use on the data. This will
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
         %smooth   Smooth response data
         %  A = smooth(T) smooths the Trace's data using a moving average
         %  filter.
         %
         %  smooth requires the signal fitting toolbox.  For additional
         %  options, see that smooth
         % See also smooth
         for n = 1:numel(A)
            A(n).data = smooth(A(n).data,varargin{:});
         end
      end
      
      function T = taper(T, style, R)
         %taper   apply a taper to a trace
         % trace = trace.taper() applies a cosine (tukey) taper to the ends
         % of a trace with a default taper to the first and last 10% of the
         % trace. This is same as trace.taper('tukey', 0.2)
         %
         % trace = trace.taper(style) applies the tapering window function
         % STYLE to the trace. STYLE can be any valid windowing function
         % some possible taper styles include hanning, tukey, and gaussian.
         % see help for WINDOW for a more complete list.
         %
         % trace = trace.taper(style, R)
         % R varies in meaning according to the window style. For the
         % default cosine (tukey) taper, R is the ratio of tapered to
         % constant sections and is between 0 and 1. For example, if R =
         % 0.1 then the taper at each end of the trace is 5% of the total
         % trace length. R can be either a scalar or the same size as
         % TRACE. If R is a scalar, it is applied uniformly to each
         % trace.
         %
         % for a tukey taper, setting R ito 1 results in a hanning taper
         %
         % All tapers require the signal processing toolbox.
         %
         % See also window
         % AUTHOR: Michael West
         % Modified: Celso Reyes
         a=ver;
         HAVE_SIGBOX = ismember('Signal Processing Toolbox',{a.Name});
         if ~HAVE_SIGBOX
            error('TraceData:taper:signalToolboxNotInstalled',...
               'Using a taper requires access to the Signal Processing Toolbox');
         end
         if ~exist('style','var') || isempty(style) || strcmpi(style,'cosine')
            style = 'tukeywin';
         end
         if exist(lower(style))
            taperfun = str2func(lower(style));
         else
            error('TraceData:taper:invalidTaperType',...
               'This style of taper is not recognized.');
         end
         
         %% massage R into place
         if strcmpi(style,'tukeywin') && (~exist('R','var') || isempty(R))
            R = 0.2; %assign default taper
         end
         if exist('R','var') &&  ~isnumeric(R)
            error('TraceData:taper:InvalidRValue',...
               'R, if specified, must be numeric');
         end
         
         if isscalar(R)
            R = repmat(R,size(T));
         end
         
         if (isvector(R) && isvector(T)) && numel(R) == numel(T)
            if all(size(T)) ~= size(R)
               % same number of elements, but R is Nx1 and w is 1xN or vice-versa
               warning('TraceData:taper:columnsVsRows',...
                  ['One input (either R or the wavform) is arranged in '...
                  'columns while the other is arranged in Rows. While they '...
                  'should be the same shape, taper is continuing with R''']);
               R = R';
            end
         end
         
         if ~all(size(T) == size(R))
            error('TraceData:taper:InvalidRSize',...
               'R must either be a scalar value, or must be the same size as the input traces');
         end
         nsamples = T.nsamples();
         %% Do the window processing
         if exist('R','var')
            for N=1:numel(T)
               T(N) = T(N) .* window(taperfun, nsamples(N), R(N));
            end
         else
            for N=1:numel(T)
               T(N) = T(N) .* window(taperfun, nsamples(N));
            end
         end
         
      end
      
      function [tf, msg] = compatiblewith(A, B)
         %compatiblewith   confirm units, samplerate, and data length match
         %  tf = A.compatiblewith(B) will make sure that A and B have
         %  matching units, sample frequencies, and data length.
         %  If units are empty for either A or B, then units will pass
         %  If samplerate is empty for either A or B, then samplerate will
         %  pass. samplerate is compared within a tolerance of 10e-2
         %
         %  [tf, msg] = A.compatiblewith(B) will also return a message
         %  describing how the test failed.
         %
         %  sample usage:
         %    % assume A & B are TraceData
         %    if A.compatiblewith(B)
         %       dosomething(A, B)
         %    end
         %
         % See also assertCompatiblewith
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
      
      function assertCompatiblewith(A, B)
         %assertCompatiblewith  asserts units, samplerate, and data length match
         %  assertCompatiblewith(A, B) will error unless A and B have
         %  matching units, sample frequencies, and data length. The error
         %  message will describe what is wrong
         %
         %  use this within a try-catch, or when debugging
         %
         % sample debugging usage:
         %   % assume A & B are TraceData
         %   A.assertCompatiblewith(B)
         %   C = A + B.data;
         %
         % sample prduction usage:
         %   try
         %     A.assertCompatiblewith(B)
         %     C = A + B.data;
         %   catch er
         %     % handle this failure somehow
         %   end
         %
         % See also compatiblewith
         [tf, msg] = compatiblewith(A, B);
         assert(tf, 'TraceData:compatabilityCheckFailed', msg);
      end
      
      %% stacking functions
      function out = stack(T)
         %stack  stacks data from array of traces
         %   StackedTraces = stack(traces)
         %   ASSUMES frequencies are the same. data does not need to be the same
         %   length, but shorter traces will be padded with zeros at the end
         %   prior to stacking.
         %
         %   Stacks all traces, regardless of dimension
         %
         %   Data is summed, but the average is not taken, nor is it normalized. You
         %   may wish to change the station and/or channel names to reflect the
         %   properties of this trace. Possibly change the units, also, if that
         %   makes sense.
         %
         %   Output retains the same info as the very first trace (minus history)
         %   the station name becomes the original name with "- stack (N)" tacked onto
         %   the end.
         %
         %   To ensure frequency and time matching, use ALIGN
         %
         %   See also trace.align
         
         out = T(1);
         out.station = [out.station ' - stack (' num2str(T) ')'];
         out.data = sum(double(T),2);
      end
      function stackedTraces = binStack(T,nBins,binOverlap)
         %binStack   Stack traces with specified number of traces per stack.
         %
         %USAGE: stk = binStack(T,nBins,binOverlap)
         %    If input T contains 100 traces then:
         %    stk = binStack(T,20,0) % stk has 5 stacks of 20 traces
         %    stk = binStack(T,5,0)  % stk has 20 stacks of 5 traces
         %    stk = binStack(T,20,10)  % stk has 9 stacks of 20 traces
         %
         %OUTPUTS: stk - Array of stacked traces
         
         % Author: Dane Ketner, Alaska Volcano Observatory
         
         nw = numel(T);
         inc = nBins - binOverlap;
         n=1;
         while 1
            if (n-1)*inc+nBins > nw
               return
            else
               stackedTraces(n) = stack(T((n-1)*inc+1:(n-1)*inc+nBins));
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
      function setParameter(name, val)
         %setParameter  controlstate behavior for the TraceData objects
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
      
      newunit = autoscale(axishandle, oldunit);
      

   end
end

