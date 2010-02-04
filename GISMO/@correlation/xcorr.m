function c=xcorr(c,varargin)

% C = XCORR(C)
% This function calculates and fills in the correlation and lag fields in a
% correlation object. The input is a correlation object, presumeably with
% empty correlation and lag fields. c.C is a matrix of maximum correlation
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
%
%
% -- DEPRICATED ALGORITHMS ---------------------------------------------
% Because these algorithms seem to have little or no advantages over the
% '1xr' algorithm they will likely not be updated or improved.
%
% C = XCORR(C,...,'dec') Same as 1xr but decomposes complex numbers for
% calculation. Mathworks suggests this approach may be faster in some
% circumstances. However, initial testing found it slower that the 1xr
% algorithm.
%
% C = XCORR(C,...,'1x1') Use single trace against single trace algorithm.
% Conceivably faster when memory is very limited. In practice I have yet to
% encounter a situation where this algorithm benchmarks faster than the
% 1xr.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



% GET INPUT PARAMETERS
if ~isa(c,'correlation')
    disp('First input parameter must be a correlation object');
end
algorithm = '1xr';
c1 = correlation;
c1 = set(c1,'WAVEFORM', get(c,'WAVEFORM') );
c1 = set(c1,'TRIG', get(c,'TRIG') );



% CHECK FOR TRACE SUBSET
if length(varargin)>1
    if isa(varargin{end},'double') 
        index = varargin{end};
        varargin = varargin(1:end-1);
    end;
end;

    % CHECK ALGORITHM
if length(varargin)>0
    if ischar(varargin{end})
        algorithm = lower(varargin{end});
        varargin = varargin(1:end-1);
    end;
end;

    % APPLY CROPPING
if length(varargin)>0
    if length(varargin{end})==2       % check for cropping values
        pretrig =  varargin{1}(1);
        posttrig = varargin{1}(2);
        c1 = crop(c,pretrig,posttrig);      
    end
end;

    
    
% CREATE MATRIX OF DATA FROM WAVEFORM ARRAY
% The correlation object is modified here into a Matlab structure that
% shares similar fields to the object except that the the trace data is
% stored in a matrix instead of in a waveform object. This structure is
% passed to the correlation subroutines as 'd'. The matrix structure
% improves computation speed because fft and other routines are optomized
% for matrices. This structure is based on the correlation object version
% 0. 
d.start = get(c1.W,'START_MATLAB');
d.Fs    = get(c1.W(1),'Fs');
d.trig  = c1.trig;
d.w     = [];
for i = 1:length(c1.W)
    d.w(:,i) = get(c1.W(i),'DATA');
end;
clear c1


% EXECUTE CROSS CORRELATION
if exist('pretrig') && exist('posttrig')
    disp(['using ' algorithm ' algorithm on the time interval [' num2str(pretrig) ' ' num2str(posttrig) '] ...' ]);
else
    %disp(['using ' algorithm ' algorithm ...']);
end    
if strcmp(algorithm,'1x1')==1
	d = xcorr1x1(d);
  elseif strcmp(algorithm,'1xr')
  	d = xcorr1xr(d,0);
  elseif strncmpi(algorithm,'int',3)
  	d = xcorr1xr(d,1);
  elseif strcmp(algorithm,'dec')
  	d = xcorrdec(d);
  elseif strcmp(algorithm,'row')
  	d = xcorrrow(d,c,index);
else
    error('Correlation algorithm not recognized');
end;


% ASSIGN CORRELATION PARAMETERS TO ORIGINAL DATA
c = set( c , 'CORR' , d.C );
c = set( c , 'LAG'  , d.L  );
clear d



