function c=xcorr(c,varargin)
% function c=xcorr(c,varargin)
   
   % C = XCORR(C)
   % This function calculates and fills in the correlation and lag fields in a
   % correlation object. The input is a correlation object, presumeably with
   % empty correlation and lag fields. c.corrmatrix is a matrix of maximum correlation
   % values normalized so that autocorrelations are 1. c.L is the lag time in
   % between the two waveforms required for maximum correlation. To acheive
   % maximum alignment, the value in position (i,j) should be added to the
   % trigger time of trace j, or subtracted from trigger i. Traces can be
   % aligned with the routine ADJUSTTRIG.
   %
   % By default, peak cross correlation values and lag times are NOT
   % interpolated for sub-sample lag time because this requires a 30-40%
   % increase in CPU time. For some uses, such as relative earthquake
   % locations and coda wave interferometry, such precision is necessary. In
   % these cases, consider the INTERP option below.
   %
   % C = XCORR(C,[PRETRIG POSTTRIG]);
   % Perform cross correlation on a cropped portion of the data only. This is
   % useful when you wish to keep the entire waveform but align the traces based on
   % the correlation of a particular wavelet. PRETRIG and POSTTRIG are the
   % time in seconds relative to the trigger time. Note that PRETRIG is
   % negative for times before the trigger.
   %
   % C = XCORR(C,...,'1xr') Use single trace against one row algorithm
   % (default).
   %
   % C = XCORR(C,...,'interp') Perform 2nd-order polynomial fitting to
   % estimate sub-sample lag time. Sub-sample alignment requires an addition
   % 30-40% CPU time but results in highest precision lag times possible.
   %
   % C = XCORR(C,...,'row',INDEX) Run correlation only on the traces specified
   % by INDEX. Each trace of INDEX is correlated against the entire set of
   % waveforms. This is useful if a small number of traces has been added to a
   % large correlation matrix. Insead of recomputing the entire correlation
   % and lag matrices, the routine allows only the "added" lines to be filled
   % in. The syntax is a bit clunky. This routine requires the 'row' algorithm
   % and the INDEX list. The two must be used together. Polynomial
   % interpolation of lag values is always used with this algorithm.

   % FIXME FIXME FIXME mid-correction
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   algorithm = '1xr'
   triggerRange = [];
   switch nargin
      case 1 % xcorr(C) :  default behavior
         algorithm = '1xr'
      case 2 % xcorr(C, algorithm)
         algorithm = varargin{1};
      case 3 % xcorr(C, [pretrig posttrig], algorithm)
         if isnumeric(varargin{1})
            triggerRange = varargin{1};
            algorithm = varargin{2};
         else
      case 3 % xcorr(C, 'row', indexList)
      case 4 % xcorr(C, [pretrig posttrig], 'row', indexList)
   end
   %}
   
   c1 = NewCorrelation;
   c1.traces = c.traces;
   c1.trig = c.trig;
   
   if ~exist('algorithm','var') || isempty(algorithm)
      algorithm = '1xr';
   end
   
   if exist('triggerRange','var') && ~isempty(triggerRange)
      assert(numel(triggerRange)==2, 'triggerRange needs to be two numbers: [pretrig, posttrig]');
      c1 = crop(c, triggerRange(1), triggerRange(2));
   end
  
   
   % CHECK FOR TRACE SUBSET
   if length(varargin)>1 && isnumeric(varargin{end})
         index = varargin{end};
         varargin = varargin(1:end-1);
   end
   
   % CHECK ALGORITHM
   if ~isempty(varargin) && ischar(varargin{end})
         algorithm = lower(varargin{end});
         varargin = varargin(1:end-1);
   end
   
      
   % APPLY CROPPING
   if ~isempty(varargin)  && length(varargin{end}) == 2 % check for cropping values
         pretrig =  varargin{1}(1);
         posttrig = varargin{1}(2);
         c1 = crop(c,pretrig,posttrig);
   end
   
   
   
   % CREATE MATRIX OF DATA FROM WAVEFORM ARRAY
   % The correlation object is modified here into a Matlab structure that
   % shares similar fields to the object except that the the trace data is
   % stored in a matrix instead of in a waveform object. This structure is
   % passed to the correlation subroutines as 'd'. The matrix structure
   % improves computation speed because fft and other routines are optomized
   % for matrices. This structure is based on the correlation object version
   % 0.
   d.start = c1.traces.firstsampletime();
   d.Fs    = c1.traces(1).samplerate();
   d.trig  = c1.trig;
   d.w = double(c1.traces);
   clear c1
   
   
   % EXECUTE CROSS CORRELATION
   if exist('pretrig','var') && exist('posttrig','var')
      disp(['using ' algorithm ' algorithm on the time interval [' num2str(pretrig) ' ' num2str(posttrig) '] ...' ]);
   end
   
   %because we're passing struct instead of object, these are now static
   switch algorithm
      case '1xr'
         d = NewCorrelation.xcorr1xr(d,0);
      case 'int'
         d = NewCorrelation.xcorr1xr(d,1);
      case 'row'
          assert(exist('index','var'), 'algorithm ''row'' requires an index parameter');
          d = NewCorrelation.xcorrrow(d,c,index);
      otherwise
         error('Correlation algorithm not recognized');
   end 
   
   % ASSIGN CORRELATION PARAMETERS TO ORIGINAL DATA
   c.corrmatrix = d.corrmatrix;
   c.lags = d.lags;
end
