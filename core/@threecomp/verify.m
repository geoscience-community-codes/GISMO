function [conflicts] = verify(TC)

%VERIFY Check for property conflicts in the threecomp object.
% [CONFLICTS] = VERIFY(TC) Check property conflicts of a threecomp object. Runs a
% series of tests to ensure that the threecomp object meets minimum
% standards and is suitable for further processing.  
%
% The output term CONFLICTS is a list of booleans showing the result of
% various consistency tests. A conflict string of '00000' shows that no 
% conflicts were found. The presence of 1's denote failed tests. Specifically:
%   position 1:  start times don't match
%   position 2:  end times don't match
%   position 3:  sample rates don't match
%   position 4:  units don't match
%   position 5:  station names don't match
%   position 6:  insufficient data length. Minimum 25 samples required.
%   position 7:  component tuple not recognized (ZNE, ZRT, Z21)
%
% This function is mostly likely to be called from within other
% threecomp functions.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



for n = 1:length(TC)
    conflicts{n} = do_one(TC(n),num2str(n));
end
conflicts = reshape(conflicts,size(TC));




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process a single threecomp trace tuple
function conflict = do_one(TC,num)

conflict = '0000000';

if any(isempty(TC.traces))
    disp(['problem in element ' num ': one or more empty waveforms']);
    conflict(6) = '1';
    return
end


% CHECK START TIMES
t = get(TC.traces,'START_MATLAB');
if ( t(2)~=t(1) ) || ( t(3)~=t(1) )
    disp(['problem in element ' num ': traces have different start times']);
    conflict(1) = '1';
end;


% CHECK END TIMES
t = get(TC.traces,'END_MATLAB');
if ( t(2)~=t(1) ) || ( t(3)~=t(1) )
    disp(['problem in element ' num ': traces have different end times']);
    conflict(2) = '1';
end;


% CHECK FREQUENCIES
freq = get(TC.traces,'FREQ');
if ( freq(2)~=freq(1) ) || ( freq(3)~=freq(1) )
    disp(['problem in element ' num ': traces have different frequencies']);
    conflict(3) = '1';
end;


% CHECK FOR COMMON UNITS
units = get(TC.traces,'UNITS');
tf = strcmpi(units,units(1));
if ~all(tf)
    disp(['problem in element ' num ': traces have different units']);
    conflict(4) = '1';
end


% CHECK FOR COMMON STATION, NETWORK, LOCATION NAMES
sta = get(TC.traces,'STATION');
tf = strcmpi(sta,sta(1));
if ~all(tf)
    disp(['problem in element ' num ': traces have different station codes.']);
    conflict(5) = '1';
end


% CHECK FOR SUFFICIENT DATA LENGTH
dataLength = get(TC.traces,'DATA_LENGTH');
if min(dataLength)<25
    disp(['problem in element ' num ': traces are too short. Not enough samples.']);
    conflict(6) = '1';
end



% CHECK ARRANGEMENT OF CHANNELS IN WAVEFORM OBJECT
channels = get(TC.traces,'CHANNEL');
if any([ length(channels{1})<3 length(channels{2})<3 length(channels{3})<3 ])
    disp(['problem in element ' num ': channel codes have less than three characters']);
    conflict(7) = '1';
elseif ~strcmpi(channels{1}(3),'Z')
    disp(['problem in element ' num ': First channel character is not Z component']);
    conflict(7) = '1';
elseif ~strcmpi(channels{2}(3),'N') && ~strcmpi(channels{1,2}(end),'R') && ~strcmpi(channels{1,2}(end),'1')
    disp(['problem in element ' num ': channel character is not N, R, or 2 component']);
    conflict(7) = '1';
elseif ~strcmpi(channels{3}(3),'E') && ~strcmpi(channels{1,3}(end),'T') && ~strcmpi(channels{1,3}(end),'2')
    disp(['problem in element ' num ': Third channel character is not E, T, or 1 component']);
    conflict(7) = '1';
end

