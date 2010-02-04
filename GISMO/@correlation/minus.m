function c = minus(c,varargin)

% C = MINUS(C,I)
% The function subtracts the waveform specified by trace index I from all
% other traces. The resulting correlation object has the same number of
% traces as the original though trace I is essentially zero amplitude.
%
% C = MINUS(C)
% Short hand version of MINUS where I is assumed to be the last trace in
% the list. That is, MINUS(C, get(C,'TRACES') ). This use is common
% following the STACK routine.
%
% Before using MINUS, time windows need to be cropped to the same interval
% relative to the triggers. This is most easily accomplished using the CROP
% function prior to MINUS. If the traces have not been cropped, MINUS will
% attempt to figure out which time window of data should be differenced.
% This can result in unanticipated signals at the ends of each trace.
% Caveat Emptor!
%
% MINUS will erase the CORR, LAG, STAT, LINK and CLUST fields from the
% objects. After differencing, these fields are no longer valid. 
% 
% The traces are not normalized prior to subtracting. For most
% applications the user will first want to normalize the trace amplitudes
% using the NORM function. Typically, plots of the residual data will use
% the 'raw' plotting option.
%
% In order to be differenced, the "phase shift" of the samples within the
% trace must be the same. If it is not, MINUS will make a call to ALIGN to
% resample all traces such that one sample falls directly on the trigger
% time.
% 
% Example - subtract the stacked waveform from each trace
%   c = xcorr(c)
%   c = adjusttrig(c)
%   c = crop(c,-3,5)
%   c = stack(c)
%   c = norm(c)      % stacked waveform is the last trace
%   c_residual = minus(c)
%   plot(c_residual,'raw');

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% READ & CHECK ARGUMENTS
if (nargin>2)
    error('Wrong number of inputs');
end;

if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end

if ( length(varargin) == 1 )
    I = varargin;
    if length(I) > 1
        error('Only one trace can be subtracted from the others');
    end
else
    I = get(c,'TRACES');
end

if check(c,'SCALE')
    disp('Warning: Traces appear to have very different overall amplitudes');
end




% CREATE CORREATION OBJECT FOR INTERNAL MANIPULATIONS
c1 = correlation;
c1 = set(c1,'WAVEFORM', get(c,'WAVEFORM') );
c1 = set(c1,'TRIG', get(c,'TRIG') );
if exist('index')               % Is this necessary?
   c1 = subset(c1,index); 
end


% CHECK IF TRACES ARE DESCRITIZED ON THE SAME INVERVALS
t = 86400 * (c1.trig - get(c1.W,'START'));
Fs = get(c1,'Fs');
sampleshift = mod(t,1/Fs);
if (mean(sampleshift) ~= sampleshift)   % if all sampleshifts are the same
    c1 = align(c1);
end


% CHECK IF TRACES ARE EQUALLY CROPPED
pretrig  = get(c1,'START') - get(c1,'TRIG');
posttrig = get(c1,'END')   - get(c1,'TRIG');
if (mean(pretrig)~=pretrig(1)) || (mean(posttrig)~=posttrig(1))
    center = mean([pretrig ; posttrig])*86400;
    pretrig = center - (0.5 * get(c1,'DATA_LENGTH') * get(c1,'Period'));
    posttrig = pretrig + (get(c1,'DATA_LENGTH')+1) * get(c1,'Period');
    % is it the right length?
    c1 = crop(c1,pretrig,posttrig);
end


for i = 1:length(c.trig)
    %c.W(i) = minus( c1.W(i) , c1.W(I) );
    d = get(c1.W(i),'Data') - get(c1.W(I),'Data');
    c.W(i) = set( c.W(i) , 'Data' , d);
    c.trig(i) = c1.trig(i);
end
c.C = [];
c.L = [];
c.stat = [];
c.link = [];
c.clust = [];


