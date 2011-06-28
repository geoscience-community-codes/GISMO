function val = check(c,varargin)

% Check various features of a correlation object.
%
% VAL = CHECK(C,'OFFSET') Check to see if traces have the same amount of 
% time before and after their respective trigger times. VAL = 0 means that
% the traces are not similarly aligned on their trigger times. VAL = 1
% means that thet are, to within a tolerance of one sample period.
%
% VAL = CHECK(C,'STA') Check to see if traces have the same station codes.
% VAL = 0 means that the traces do not all share the same station code. VAL
% = 1 means that they do. A match is sought only on the first three
% characters of the station name (there are internal reasons for this).
%
% VAL = CHECK(C,'FREQ') Check to see if traces have the same frequency.
% VAL = 0 means that the traces do not all share the same frequency. VAL
% = 1 means that they do.
%
% VAL = CHECK(C,'SAMPLES') Check to see if traces have the same station
% codes. VAL = 0 means that the traces do not all share the same station
% code. VAL = 1 means that they do.
%
% VAL = CHECK(C,'CHAN') Check to see if traces have the same channel codes.
% VAL = 0 means that the traces do not all share the same channel code. VAL
% = 1 means that they do.
%
% VAL = CHECK(C,'SCALE') Check to see if traces have similar maximum
% amplitudes. This is a rough check to determine whether the traces have
% been normalized. VAL = 0 means that at least one trace has a maxium
% amplitude that is 50% larger than the mean of the other traces (zero
% traces are ignored).
%

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% GET INPUT PARAMETERS
if ~isa(c,'correlation')
    disp('First input parameter must be a correlation object');
end

if length(varargin)==0
    error('Wrong number of inputs');
end

type = varargin{1};
val = 1;

if strncmpi(type,'OFF',3)
    val = do_offset(c,val);
elseif strncmpi(type,'STA',3)
    val = do_stations(c,val);
elseif strncmpi(type,'CHA',3)
    val = do_channels(c,val);
elseif strncmpi(type,'FRE',3)
    val = do_frequency(c,val);
elseif strncmpi(type,'SAM',3)
    val = do_samples(c,val);
elseif strncmpi(type,'SCA',3)
    val = do_scale(c,val);
else
    error('CHECK requires a valid method as second parameter.');
end



%% Check offsets
function val = do_offset(c,val)

srt_offset = ( get(c,'Trig') - get(c,'Start') ) * 86400;
end_offset = ( get(c,'End') - get(c,'Trig') ) * 86400;

if ( max(srt_offset) - min(srt_offset) ) > get(c,'Period')
	val = 0;
end

if ( max(end_offset) - min(end_offset) ) > get(c,'Period')
	val = 0;
end


    
%% Check station codes
function val = do_stations(c,val)
   
sta = get(c,'STA');
if ~iscell(sta)
   sta = {sta}; 
end
tf = strncmpi(sta,sta(1),3);
if length(find(tf)) ~= length(tf)
    val = 0;
end
if isempty([sta{:}])
    val = 1;
end
    

%% Check channel codes
function val = do_channels(c,val)
   
chan = get(c,'CHAN');
if ~iscell(chan)
   chan = {chan}; 
end
tf = strcmpi(chan,chan(1));
if length(find(tf)) ~= length(tf)
    val = 0;
end
if isempty([chan{:}])
    val = 1;
end


%% Check frequencies 
function val = do_frequency(c,val)
   
w = get(c,'WAVES');
x = get(w,'FREQ');
if numel(x)>0       % not sure why this loop is needed but it works ???numel(x)
    tf = find(x==x(1));
    if length(find(tf)) ~= get(c,'traces')
        val = 0;
    end
end


%% Check number of samples in traces
function val = do_samples(c,val)
   
w = get(c,'WAVES');
x = get(w,'DATA_LENGTH');
if numel(x)>0   
    tf = find(x==x(1));
    if length(find(tf)) ~= get(c,'traces')
        val = 0;
    end
end



%% Check absolute mplitude of the traces
function val = do_scale(c,val)
   
d = get(c,'DATA');
x = max(abs(d));
f = find(x>0);
if ( max(x) / mean(x(f)) ) > 1.5
    val = 0;
end


