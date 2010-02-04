function [WW,WWxc] = mastercorr_scan(WW,WWsnippet,threshold)

%MASTERCORR_SCAN scans a waveform for events which match a master.
% W = MASTERCORR_SCAN(W,SNIPPET,THRESHOLD) scans through continuous data,
% W, for sections that match the (much shorter) waveform SNIPPET. SNIPPET
% is the so-called master event. A time domain convolution algorithm is
% used to compare SNIPPET at all lag offsets against waveform W. A
% normalized cross-correlation function is derived in the process. Any
% waveform segment which cross correlates with SNIPPET above a correlation
% value of THRESHOLD is considered a successful match. These matches are
% then saved as fields in W:
%
% MASTERCORR_TRIG       % "trigger" times of matches in Matlab date format
% MASTERCORR_CORR       % value of the correlation. should be >= threshold
% MASTERCORR_ADJACENT_CORR     % max correlation of adjancent peak(s) 
% MASTERCORR_SNIPPET    % the actual snippet is stored in the waveform for
%                         future reference
% 
% If W is of size NxM and SNIPPET is 1x1, then the same SNIPPET is applied
% to each element of W. If SNIPPET is NxM and W is 1x1, each SNIPPET is
% applied individually to W and the returned W is NxM. If W and SNIPPET are
% both NxM then SNIPPETs are applied one-by-one to their respective element
% of W.
%
% [W,XC] = MASTERCORR_SCAN(W,SNIPPET,THRESHOLD) has same usage except that
% the actual cross correlation functions are returned in XC. XC is
% essentially a waveform the same as W, except that the waveform data has
% been replaced with the normalized cross correlation function(s).
%
% *** NOTE ABOUT TRIGGER TIMES ***
% MASTERCORR_SCAN has the ability to syncronize its trigger times on a
% master event trigger. This allows traces to be referenced to a
% user-selected point in the waveform (such as a P wave pick). The
% resulting times for detected events will then be referenced to this time.
% This can be useful in later stages of processing as these reference times
% become the trigger times in the correlation objects produced by
% MASTERCORR_EXTRACT. If no such reference in included, the default
% reference time is the start time of SNIPPET. To include this feature, the
% waveform SNIPPET should include a field called TRIGGER. TRIGGER is a
% scalar time (Matlab format). See MASTERCORR_COOKBOOK for example use.
%
% See also mastercorr_plot_stats, mastercorr_cookbook, mastercorr_extract

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$
% TODO: HANDLE NO TRIGGERS



% CHECK INPUTS
if nargin ~= 3
    error('Incorrect number of inputs');
end
if ~isa(WW,'waveform') | ~isa(WWsnippet,'waveform')
    error('First two arguments must be waveform objects');
end
if threshold<-1 | threshold>1
    error('Correlation threshold must be between -1 and 1');
end


% SET SNIPPET LENGTH
if numel(WW)>1 & numel(WWsnippet)==1
    disp('One snippet applied to multiple continuous waveforms ...');
    WWsnippet = repmat(WWsnippet,size(WW));
elseif numel(WW)==1 & numel(WWsnippet)>1
    disp('Multiple snippets applied to one continuous waveform ...');
    WW = repmat(WW,size(WWsnippet));
elseif (numel(WW)==numel(WWsnippet)) & (size(WW,1)==size(WWsnippet,1))
    disp('One snippet per continuous waveform ...');
else
    error('Mismatch in matrix size between W and SNIPPET arguments');
end


% PROCESS EACH WAVEFORM
WWxc = WW;    % establishes the dimensions of WWxc
fprintf('%s',['Processing ' num2str(numel([1:10])) ' waveforms  ']);
for n = 1:numel(WW)
    %disp(['Processing ' num2str(n) ' out of ' num2str(numel(WW)) ' waveforms ...')]);
    fprintf('%s','.');
    [WW(n),WWxc(n)] = do_single_waveform(WW(n),WWsnippet(n),threshold);
end
fprintf('\n');
 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
function [W,Wxc] = do_single_waveform(W,Wsnippet,threshold)


% SET SNIPPET TRIGGER TIME
if ~ismiscfield(Wsnippet,'TRIGGER')
    Wsnippet = addfield(Wsnippet,'TRIGGER',get(Wsnippet,'START'));
    %disp('Adding trigger');
end
trigger = get(Wsnippet,'TRIGGER');
if trigger<get(Wsnippet,'START') | trigger>get(Wsnippet,'END')
    warning('Note that trigger time is outside the time range of the snippet');
end
timeOffset = get(Wsnippet,'TRIGGER') - get(Wsnippet,'START');


% CHECK SAMPLE RATES
tolerance = 0.5;   % allowable time slop in samples
dataLengthMisMatch = (abs(get(Wsnippet,'PERIOD')-get(W,'PERIOD'))*get(Wsnippet,'DATA_LENGTH'));
if dataLengthMisMatch > tolerance*get(Wsnippet,'PERIOD')
    disp(['Continuous waveform sample rate: ' num2str(get(W,'FREQ'))]);
    disp(['Waveform snippet sample rate:    ' num2str(get(Wsnippet,'FREQ'))]);
    error('Sample rates do not match waveform snippet within tolerance. Consider using WAVEFORM/ALIGN.');
end


% GET AMPLITUDE COEFFICIENTS
%Wcoeff = xcorr( double(W).^2 , ones(get(Wsnippet,'DATA_LENGTH'),1) );
%Wcoeff = Wcoeff(get(W,'DATA_LENGTH'):end);
%Wcoeff = 1 ./ sqrt(Wcoeff);
Wcoeff = conv( double(W).^2 , ones(get(Wsnippet,'DATA_LENGTH'),1) );
Wcoeff = Wcoeff(get(Wsnippet,'DATA_LENGTH'):end);
Wcoeff = 1 ./ sqrt(Wcoeff);
WsnippetCoeff = 1/sqrt(sum(double(Wsnippet).^2));


% GET XCORR FUNCTION AS A WAVEFORM
XC = conv(double(W),flipud(double(Wsnippet)));
XC = XC(get(Wsnippet,'DATA_LENGTH'):end);
XC = XC .* Wcoeff .* WsnippetCoeff;     % apply normalization
Wxc = set(W,'Data',XC);
Wxc = waveform;
Wxc = set( Wxc , 'STATION' , get(W,'STATION') , 'CHANNEL' , get(W,'CHANNEL') );
Wxc = set( Wxc , 'START' , get(W,'START') , 'FREQ' , get(W,'FREQ') );
Wxc = set( Wxc , 'DATA' , XC );


% ADD MATCH TIMES TO WAVEFORM
allPeaks = find(getpeaks(Wxc));
allPeakValues = XC(allPeaks);
f = find( allPeakValues>=threshold );
goodPeaks = allPeaks(f);
goodPeakValues = allPeakValues(f);
timeVector = get(Wxc,'TIMEVECTOR');
dataVector = get(Wxc,'DATA');
mastercorr_trig = timeVector(goodPeaks) + timeOffset;
mastercorr_corr = goodPeakValues;
adjacentPeakValues = find_adjacent_peaks(f,allPeaks,allPeakValues,goodPeaks)';
W = addfield(W,'MASTERCORR_TRIG',mastercorr_trig);
W = addfield(W,'MASTERCORR_ADJACENT_CORR',adjacentPeakValues);
W = addfield(W,'MASTERCORR_CORR',mastercorr_corr);
W = addfield(W,'MASTERCORR_SNIPPET',Wsnippet);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
function adjacentPeakValues = find_adjacent_peaks(f,allPeaks,allPeakValues,goodPeaks)

% allPeaks:         index of peaks in coorelation function
% allPeakValues:    cross correlation value of peak
% f:                indicates those allPeaks which surpass the threshold
% goodPeaks:        index of peaks (above threshold) in correlation function
% goodPeakValues:   cross correlation value of peak (above threshold)


if numel(goodPeaks)==0
    adjacentPeakValues = [];
else
    % FIRST PEAK
    if goodPeaks(1)==allPeaks(1)
        adjacentPeakValues(1) = allPeakValues(f(1)+1);
    else
        adjacentPeakValues(1) = max([allPeakValues(f(1)-1)' ; allPeakValues(f(1)+1)']);
    end
    % END PEAK
    if goodPeaks(end)==allPeaks(end)
        adjacentPeakValues(numel(f)) = allPeakValues(f(end)+1);
    else
        adjacentPeakValues(numel(f)) = max([allPeakValues(f(end)-1)' ; allPeakValues(f(end)+1)']);
    end
    % MIDDLE PEAKS
    adjacentPeakValues(2:end-1) = max([allPeakValues(f(2:end-1)-1)' ; allPeakValues(f(2:end-1)+1)']);
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
function fieldExists = ismiscfield(W,fieldName)

% For W of length 1 only.

miscFields = get(W,'misc_fields');

if find(strcmpi(miscFields,fieldName)) 
    fieldExists = 1;
else
    fieldExists = 0;
end



