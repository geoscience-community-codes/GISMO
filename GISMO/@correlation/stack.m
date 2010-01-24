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

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


% READ & CHECK ARGUMENTS
if (nargin>2)
    error('Wrong number of inputs');
end;

if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end

if (length(varargin)==1)
   index = varargin{1}; 
end


% CREATE CORREATION OBJECT FOR INTERNAL MANIPULATIONS
c1 = correlation;
c1 = set(c1,'WAVEFORM', get(c,'WAVEFORM') );
c1 = set(c1,'TRIG', get(c,'TRIG') );
if exist('index')
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


% ADJUST STACK LENGTH BY ONE SAMPLE IF NECESSARY
if (get(c1,'DATA_LENGTH') < get(c,'DATA_LENGTH'))
    for i = 1:length(c1.trig)
        Wtmp = c1.W(i);
        data = get(Wtmp,'DATA');
        data(end+1) = data(end);
        Wtmp = set(Wtmp,'DATA',data);
        c1.W(i) = Wtmp;
    end
    %disp('Stack was padded with one additional sample for consistency');
end


c.W(end+1) = stack(c1.W);
c = verify(c);        %%%%%%% added on 12/15/2007 %%%%%%%%%%%%%%%%%
c.trig(end+1) = c1.trig(1);
c.stat = [];
c.link = [];
c.clust = [];
if size(c.C,1) > 0
    c = xcorr(c,'row', get(c,'TRACES') );
end
