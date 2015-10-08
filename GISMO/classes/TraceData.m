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
   
   
   properties
      data % time-series data, kept in a column
      samplefreq % sample frequency of the time-series data in samples/sec
      units % text description of data units
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
                  obj.samplefreq = get(varargin{1},'freq');
                  obj.data = get(varargin{1},'data');
                  obj.units = get(varargin{1}, 'units');
               end
            case 3 % TraceData(data, samplefreq, units);
               obj.data = varargin{1};
               obj.samplefreq = varargin{2};
               obj.units = varargin{3};
         end %switch
      end
         
      function obj = set.data(obj, values)
         % set.data ensures that data is always stored in a column
            obj.data = values(:);
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
         %  toether by explicitly adding the data from one to the other:
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
            A.data = A.data - B; % subtract either a scalar or a COLUMN of numbers (same length as TraceData's data)
         else
               error('TraceData:minus:unknownClass','do not know how to subtract a %s from a TraceData object', class(B));
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
            A.data = A.data .* B; % B should be either scalar or same size as obj.data
         elseif isnumeric(A)
            [A, B] = deal(B, A); % swap values
            A.data = A.data .* B;
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
            A.data = A.data ./ B; % subtract either a scalar or a COLUMN of numbers (same length as TraceData's data)
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
         A.data = A.data .^ B; % B should be scalar or same length as A
      end
      
      function A = uminus(A)
         A.data = -A.data;
      end
     
      function A = abs(A)
         A.data = abs(A.data);
         A.units = ['abs (', A.units, ')'];
      end
      
      function A = sign(A)
         A.data = sign(A.data);
         A.units = ['sign(', A.units, ')'];
      end
               
      %% more complicated 
      function A = diff(A, varargin)
         % FREQUENCY is not considered!
         % otherwise, would be X = diff(X) .* Freq
         if isempty(varargin)
            A.data = diff(A.data) .* A.samplefreq;
            A.data = diff(A.data);
         else
            error('not implemented yet');
         end
         % deal with units
         %{
         % swiped directly from waveform, needs editing.
         tempUnits = allUnits{I};
      whereInUnits = strfind(tempUnits,' * sec');
      if isempty(whereInUnits)
         w(I) = set(w(I),'units', [tempUnits, ' / sec']);
      else
         tempUnits(whereInUnits(1) :whereInUnits(1)+5) = [];
         w(I) = set(w(I),'units',tempUnits);
      end
         %}
      end
      
      function A = integrate(A, method)
         error('not implemented yet');
      end
               
      function A = demean(A)
         A = A - mean(A.data);
      end
      
      function A = detrend(A, varargin)
         A.data = detrend(A.data,varargin{:});
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
         f = td.samplefreq / 2 * linspace(0,1,NFFT/2+1);
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
         
         % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
         % $Date$
         % $Revision$
         
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
      
      function d = double(obj)
         % double get TraceData data as zero-padded columns
         d=[];
         for n = obj
            d(1:numel(n.data),end+1) = double(n.data);
         end
      end
      
      function tf = eq(A, B)
         tf = all(A.data == B.data) && A.freq==B.freq && strcmp(A.units, B.units);
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
      
      function [tf, msg] = testCompatibility(A, B)
         % testCompatibility confirms matching units, samplefreq, and data length
         % tf = testCompatibility(A, B) will make sure that A and B have
         % matching units, sample frequencies, and data length.  
         % If units are empty for either A or B, then units will pass
         % If samplefreq is empty for either A or B, then samplefreq will
         % pass.  samplefreq is compared within a tolerance of 10e-2
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
         elseif ~(isempty(A.samplefreq) || isempty(B.samplefreq) || isnan(A.samplefreq) || isnan(B.samplefreq) || ismembertol(A.samplefreq,B.samplefreq, TOL))
            tf = false;
            msg = sprintf('Frequencies do not match [%f] vs [%f]',A.samplefreq, B.samplefreq);
         else
            tf = true;
            msg = '';
         end
      end
      
      function assertCompatibility(A, B)
         % assertCompatibility asserts matching units, samplefreq, and data length
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
      
               
   end
   methods(Access=protected)
      
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

