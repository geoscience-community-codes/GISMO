function c = stack(c,varargin)

% c = STACK(c)
% This function appends a stacked waveform to the end of the correlation
% object. Stacking is performed with the traces aligned on their trigger
% times (as they appear in plots). In order to do this traces must be
% cropped to the same time interval relative to the triggers. This is most
% easily accomplished using the CROP function prior to STACK. If the traces
% have not been cropped, STACK will attempt to figure out which time window
% of data should be stacked. This may or may not be in the user's best
% interest. Caveat Emptor!
%
% c = STACK(c,INDEX)
% Same as above except the stack is only performed using a subset of the
% traces as specified by the index numbers, INDEX.
%
% The traces are summed, but not normalized or averaged. In order
% to be stacked, the "phase shift" of the samples within the trace must be
% the same. If it is not, STACK will make a call to ALIGN to resample all
% traces such that one sample falls directly on the trigger time. Following
% the convention of waveform, the trace time and name are based on the
% first trace that contributed to the stack.
% 
% ** NOTE TO USERS: Though most plotting routines normalize adjacent traces
% to comparable amplitudes for display, the real trace amplitudes often
% very by orders of magnitudes. Depending on the features the user is
% trying to highlight, it may make sense to normalize the trace amplitudes
% before stacking. This can be performed with the NORM function.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% READ & CHECK ARGUMENTS
if (nargin>2)
    error('Wrong number of inputs');
end;

if (length(varargin)==1)
   index = varargin{1}; 
end


% CREATE CORRELATION OBJECT FOR INTERNAL MANIPULATIONS
c1 = NewCorrelation();
c1.traces = c.traces;
c1.trig = c.trig;
if exist('index')
   c1 = subset(c1,index); 
end


% CHECK IF TRACES ARE DESCRITIZED ON THE SAME INVERVALS
t = 86400 * (c1.trig - c1.traces.firstsampletime());
Fs = c1.samplerate;
sampleshift = mod(t,1/Fs);
if (mean(sampleshift) ~= sampleshift)   % if all sampleshifts are the same
    c1 = align(c1);
end

    
% CHECK IF TRACES ARE EQUALLY CROPPED
pretrig  = c1.traces.firstsampletime() - c1.trig;
posttrig = c1.traces.lastsampletime() - c1.trig;
if (mean(pretrig)~=pretrig(1)) || (mean(posttrig)~=posttrig(1))
    center = mean([pretrig ; posttrig])*86400;
    pretrig = center - (0.5 * c1.data_length * c1.traces(1).period); %periods assumed to be same!
    posttrig = pretrig + (c1.data_length+1) * c1.traces(1).period;
    % is it the right length?
    c1 = crop(c1,pretrig,posttrig);
end


% ADJUST STACK LENGTH BY ONE SAMPLE IF NECESSARY
if (c1.data_length < c.data_length)
    for i = 1:length(c1.trig)
        Ttmp = c1.traces(i);
        data = Ttmp.data;
        data(end+1) = data(end);
        Ttmp.data = data;
        c1.traces(i) = Ttmp;
    end
    %disp('Stack was padded with one additional sample for consistency');
end


c.traces(end+1) = stack(c1.traces);
c = verify(c);        %%%%%%% added on 12/15/2007 %%%%%%%%%%%%%%%%%
c.trig(end+1) = c1.trig(1);
c.stat = [];
c.link = [];
c.clust = [];
if size(c.corrmatrix,1) > 0
    c = xcorr(c,'row', c.ntraces);
end
