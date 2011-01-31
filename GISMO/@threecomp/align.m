function TCnew = align(TC,varargin)

%ALIGN Align and trim traces in threecomp object.
% TC = ALIGN(TC) resample traces so that samples from each component align
% in time. As needed, this may include: trimming the start or end times;
% changing the sample rate; resampling traces to eliminate subsample
% offsets. If start and end times do not overlap for all traces, the
% waveforms returned will be of zero length.
%
% TC = ALIGN(TC,ALIGNFREQ) specifies an explicit frequency for the
% resampling. If no frequency is given, then traces are resampled to same
% frequency as the Z component in each threecomp object.
%
% If a trace contains fewer than 25 samples, that threecomp element will 
% not be aligned and the resulting traces will be of zero length (empty).
 
% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


GETFREQ = 1;
if ~isempty(varargin)
   alignFreq = varargin{1};
   if ~isreal(alignFreq)
      error('Threecomp:align:resampling rate must be a real number'); 
   end
   GETFREQ = 0;
end


TCnew = TC;
for n = 1:length(TC)
    if GETFREQ
       alignFreq = get(TC(n).traces(1),'FREQ');
    end
    TCnew(n) = do_one(TC(n),alignFreq);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process a single threecomp trace tuple
function TC = do_one(TC,alignFreq)


% CHECK START/END TIMES AND FREQUENCIES
SAMETIMES = 1;
SAMEFREQUENCY = 1;
SUFFICIENTLENGTH = 1;
startTime = get(TC.traces,'START_MATLAB');
endTime = get(TC.traces,'END_MATLAB');
freq = get(TC.traces,'FREQ');
dataLength = get(TC.traces,'DATA_LENGTH');
if ( startTime(2)~=startTime(1) ) || ( startTime(3)~=startTime(1) )
    SAMETIMES = 0;
end
if ( endTime(2)~=endTime(1) ) || ( endTime(3)~=endTime(1) )
    SAMETIMES = 0;
end
if ( freq(2)~=freq(1) ) || ( freq(3)~=freq(1) )
    SAMEFREQUENCY = 0;
end
if min(dataLength)<25
   SUFFICIENTLENGTH = 0; 
end



if ~SUFFICIENTLENGTH
    TC.traces = set(TC.traces,'DATA',[]);
else
    
    % ALIGN IF NECESSARY
    if ~SAMETIMES || ~SAMEFREQUENCY
        TC.traces = align(TC.traces , startTime , alignFreq );
    end
    
    % CROP TRACES IF NECESSARY
    if ~SAMETIMES || ~SAMEFREQUENCY
        samples = floor(get(TC.traces(1),'FREQ')*86400*(min(endTime) - max(startTime)));
        TC.traces = extract(TC.traces, 'TIME&SAMPLES', max(startTime), samples);
    end
    
end
