function c=xcorr(c,varargin)

% C = XCORR(C)
% This function calculates and fills in the correlation and lag fields in a
% correlation object. The input is a correlation object, presumeably with
% empty correlation and lag fields. c.C is a matrix of maximum correlation
% values normalized so that autocorrelations are 1. c.L is the lag in
% seconds between the two waveforms. That is, c.L is a small time
% correction which, when added to the second trigger value, will allow the
% two waveforms to be aligned at their maximum correlation value. To align
% traces use the routine ADJUSTTRIG.
%
% C = XCORR(C,[PRETRIG POSTTRIG]);
% Perform cross correlation on a clipped portion of the data only. This is 
% useful when you wish to keep the entire waveform but align the traces based on 
% the correlation of a particular wavelet. PRETRIG and POSTTRIG are the
% time in seconds relative to the trigger time. Note that PRETRIG is
% negative for times before the trigger.
%
% C = XCORR(C,...,'1xr') Use single trace against one row algorithm (default).
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


if length(varargin)>0

    % CHECK ALGORITHM
    if ischar(varargin{end})
        algorithm = lower(varargin{end});
        varargin = varargin(1:end-1);
    else
        algorithm = '1xr';
    end;

    % APPLY CLIPPING
    varargin
    if length(varargin{end})==2       % check for clipping values
        pretrig =  varargin{1}(1);
        posttrig = varargin{1}(2);
        c1 = clip(c,pretrig,posttrig);
    else
        c1 = c;
    end

    % ADD CORRELATION
    if isa(varargin(2),'correlation')
        c2 = varargin(2);
        algorithm = 'cxc';
    end
else
    c1 = c;
    algorithm = '1xr';
end
    
    
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
    disp(['using ' algorithm ' algorithm ...']);
end
switch algorithm
   case '1x1'
      d = xcorr1x1(d);
   case '1xr'
      d = xcorr1xr(d);
   case 'dec'
      d = xcorrdec(d);
   case 'cxc'
      d = xcorrcxc(d);
end


% ASSIGN CORRELATION PARAMETERS TO ORIGINAL DATA
c = set( c , 'CORR' , d.C );
c = set( c , 'LAG'  , d.L  );
clear d


% CREATE MATRIX OF WAVEFORM DATA
    function d = getwavematrix(c)
d.start = get(c.W,'START_MATLAB');
d.Fs    = get(c.W(1),'Fs');
d.trig  = c.trig;
d.w     = [];
for i = 1:length(c.W)
    d.w(:,i) = get(c.W(i),'DATA');
end;
