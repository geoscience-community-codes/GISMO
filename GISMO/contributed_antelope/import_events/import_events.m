function [ eqtc, varargout ] = import_events(dbname, chanfile, starttime, endtime, phase, delay, enddelay)
%IMPORT_EVENTS Import waveforms associated with earthquake events.
% EQTC = IMPORT_EVENTS(DBNAME, CHANFILE, STARTTIME, ENDTIME, ...
%                      PHASE, DELAY, ENDDELAY) returns a cell array of
% threecomp objects, waveform objects, and empty cells, containing
% waveforms organized column-wise by station and row-wise by event.  Input
% arguments are as follows:
%
%    DBNAME: Filename of an Antelope database.
%    CHANFILE: Filename of a comma-delimited list of station-channel
%    associations (see IE_READCHANS helpfile for the format).
%    STARTTIME: Start date/time in Antelope-readable string format.
%    ENDTIME: End date/time in Antelope-readable string format.
%    PHASE: Arrival phase to use (e.g. 'P', 'S')
%    DELAY: Seconds preceding arrival time to retrieve into waveforms.
%    ENDDELAY: Seconds following arrival time to retrieve into waveforms.
%
% The intent of this function is to import waveform data from multiple
% events and stations, and to store it in an organized cell array which
% preserves associations between arrivals.  Three-component data is
% retrieved if it is available, and converted to threecomp objects.
% Single-component data remains as waveform objects.  Values ETYPE, ORID,
% OTIME, SEAZ, and STYPE are also retrieved from the database and stored as
% custom fields within each waveform object.  If there is no arrival for an
% event at a station, that cell is left empty.  If three-component data is
% available but cannot be converted into a threecomp object (usually
% indicating data problems), the cell is also left empty.
%
% [EQTC, EQWF] = IMPORT_EVENTS(...) returns the aforementioned cell array
% in EQTC as well as a cell array of unadulterated waveform objects in
% EQWF.  These will be 1x1 waveforms for single-component data and 1x3
% waveforms for three-component data (including those that could not be
% converted to threecomp objects and are not present in EQTC).
%
% RETURN VALUE EXAMPLES
%
% In both EQTC and EQWF, waveforms are organized into columns by station
% and rows by event.  Here is a hypothetical three-station five-earthquake
% example; stations EG1 and EG2 are three-component, station EG3 is
% single-component.
%
% EQTC =  % EG1                EG2                EG3 
%                  []    [1x1 threecomp]    [1x1 waveform]   % Event 1
%     [1x1 threecomp]    [1x1 threecomp]                []   % Event 2
%                  []                 []    [1x1 waveform]   % Event 3
%     [1x1 threecomp]    [1x1 threecomp]    [1x1 waveform]   % Event 4
%                  []                 []    [1x1 waveform]   % Event 5
%
% EQWF =  % EG1                EG2                EG3 
%                  []     [1x3 waveform]    [1x1 waveform]   % Event 1
%      [1x3 waveform]     [1x3 waveform]                []   % Event 2
%                  []                 []    [1x1 waveform]   % Event 3
%      [1x3 waveform]     [1x3 waveform]    [1x1 waveform]   % Event 4
%      [1x3 waveform]                 []    [1x1 waveform]   % Event 5
%
% Notice that EQTC contains both threecomp objects and waveform objects.
% EQWF contains waveform objects only, but with size 1x3 for
% three-component stations and 1x1 for single-component stations.  When
% events are not recorded at a station, the cell is left empty [].
% IMPORTANT: The cell in EQTC is also left empty when a 1x3 waveform cannot
% be converted into a threecomp object, such as with event 5 at station EG1 in
% the above example.
%
% CAVEATS AND LIMITATIONS:
%
% 1. The earthquake list is taken from the origin table without
% consideration of the event table or the value of prefor.  If more than
% one origin is present for an event, they will all be retrieved.
%
% 2. The value of STYPE is taken from the chosen phase arrival, and is assumed
% to be the same across all components of three-component data.
%
% 3. Unassociated arrivals will not be retrieved.  The returned data
% structure is versatile enough that unassociated arrivals _could_ be
% stored in an intuitive way (one per row) but so far this has not been
% implemented.
%
% Author: Christopher Bruton, Geophysical Institute, University of Alaska Fairbanks
% $Date$
% $Revision$


%% Check for valid input

% dbname is checked by dbopen()

% chanfile is checked by ie_readchans()

% Convert dates.  We could pass the user input directly to Antelope in the
% query, but malformed dates could cause unexpected results.  There doesn't
% seem to be a simple way to otherwise check for valid date formats or to
% escape special characters. This way we at least ensure a valid epoch number.
starttime = str2epoch(starttime);
endtime = str2epoch(endtime);

% Set flag if dates are not given; this will prevent subset on starttime
% and endtime and instead return the whole catalogue.  Note that
% str2epoch()'s return value does not distinguish between invalid input
% (e.g. 'asdfjd') and true zero values (e.g. 'Jan 1 1970'), so this flag
% could get set inadvertently.
if (starttime == 0) && (endtime == 0)
	all_times = true;
else
	all_times = false;
	% Check date range
	if (endtime < starttime)
		error('Argument endtime must be after argument starttime.');
	end
end

% Check delay times.  These should be numbers
if ~isscalar(delay) || ~isnumeric(delay)
	error('Argument delay must be a scalar number.');
end
if ~isscalar(enddelay) || ~isnumeric(enddelay)
	error('Argument enddelay must be a scalar number.');
end

% Check that waveform time range is valid
if (enddelay + delay) <= 0
	error('Arguments delay and enddelay must denote a positive non-zero time range.');
end

% Check that phase is an alphanumeric string (perhaps this cannot be
% expected to be universally true, but the alternative would require
% checking that special characters are safe).
if ~all(isstrprop(phase,'alphanum'))
	error('Argument phase must be an alphanumeric string.');
end


%% Check output arguments

switch nargout
	case 1
		ret_eqwf = false;
	case 2
		ret_eqwf = true;
	otherwise
		error('Incorrect number of output arguments.');
end



%% Read and verify list of stations and channels

fprintf(2,'Loading and verifying station/channel list...\n');

% Open list
chanlist = ie_readchans(chanfile);

% The above function does some basic error checking but we still need to
% confirm things with the database (sitechan table)

% Open DB, read sitechan table, and close
db = dbopen(dbname,'r');
db = dblookup_table(db,'sitechan');
db = dbsort(db,'sta','chan');
[tsta,tchan] = dbgetv(db,'sta','chan');
dbclose(db);

% Now check that every station-channel pair in chanlist exists
stations = chanlist(:,1);
for n = 1:length(stations)
	channels = chanlist(n,2:4);
	channels(strcmp('',channels)) = []; % Delete empty elements
	
	tchans = tchan(strcmp(stations(n),tsta)); % Channels from tchan corresponding to station n
	for m = 1:length(channels)
		if ~any(strcmp(channels(m),tchans))
			error(['Channel ' channels{m} ' at station ' stations{n} ' does not exist in sitechan table.']);
		end
	end
end




%% Load the earthquake catalogue

fprintf(2,'Loading earthquake catalogue...\n');

% Open database
db = dbopen(dbname,'r');

% Get all arrivals (of desired phase) for origins within time period
db = dblookup_table(db,'origin');
if all_times == false
	db = dbsubset(db,['time >= ' num2str(starttime,'%f') ' && time < ' num2str(endtime,'%f')]);
end
db1 = dblookup_table(db,'assoc');
db1 = dbsubset(db1,['phase == "' phase '"']);
db = dbjoin(db,db1);

% Create station subset string
stastring = ['sta=="' stations{1} '"'];
if length(stations) > 1
	for n = 1:length(stations)
		stastring = [stastring ' || sta=="' stations{n} '"'];
	end
end

% Subset to only chosen stations
db = dbsubset(db,stastring);

% Join to arrival table
db1 = dblookup_table(db,'arrival');
db = dbjoin(db,db1);

% Sort by origin time and id
db = dbsort(db,'origin.time','orid');

% Get the values
[sta,atime,otime,orid,etype,stype,seaz] = dbgetv(db,'sta','arrival.time','origin.time','orid','etype','stype','seaz');
atime = epoch2datenum(atime);
otime = epoch2datenum(otime);

% We also want a list of unique orids.  Have to use DB operations for this
% (rather than unique()) so that sorting (by time) is preserved
db = dbgroup(db,{'origin.time','orid'});
unique_orids = dbgetv(db,'orid');

% Close database link
dbclose(db);





%% Arrange info from earthquake catalogue into a more useful format

% We want a column for each station and a row for each earthquake (origin).
% Store arrival times in this format for now, so we can later replace them
% with loaded waveforms.

% Number of stations.  Use user-specified list and order (rather than
% unique values from arrivals table) for greater flexibility.
nstations = length(stations);

% Number of earthquakes
norigins = length(unique_orids);

% Allocate an array to store arrival times
eqtimes = zeros(norigins,nstations);

% Allocate an additional array to store the indices, so we can retrieve
% other data (e.g. event type) later
eqindices = zeros(norigins,nstations);

% Now go through each arrival and place it in the array
for n = 1:length(orid)
	sta_index = find(strcmp(sta{n},stations),1);
	orid_index = find(unique_orids == orid(n),1); % Could do something more efficient here; orid is sorted in ascending order so a find is not really necessary
	eqtimes(orid_index,sta_index) = atime(n);
	eqindices(orid_index,sta_index) = n;
end





%% Load waveforms for all arrivals

% We now have an array full of arrival times at stations.  We want to load
% those waveforms into a cell array of the same shape.

% Specify the datasource
ds = datasource('antelope',dbname);

% Allocate the array
eqwf = cell(norigins,nstations);

fprintf(2,'Loading waveforms:\n');
% We'll go column by column
for ns = 1:nstations
	% Get channel names and create scnlobject
	channels = chanlist(ns,2:4);
	channels(strcmp('',channels)) = [];
	scnl = scnlobject(stations{ns},channels,'','');
	
	% Is this one or three components?
	if length(channels) == 3
		is_tc = true;
	else
		is_tc = false;
	end
	fprintf(2,'%s (%d of %d)...\n',stations{ns},ns,nstations);
	
	% Create a list of arrival times for this station
	satime_indices = find(eqtimes(:,ns) > 0);
	satimes = eqtimes(satime_indices,ns); % Usually better practice to use logical indexing directly instead of a find(), but we need the indexes themselves for later
	
	% Calculate actual start and end times
	end_times = satimes + enddelay/86400;
	start_times = satimes - delay/86400;
	
	% Load waveforms for this station and channels
	wtmp = waveform(ds,scnl,start_times,end_times);
	
	% If 3-component data, rearrange to put channels together
	if is_tc
		wtmp = reshape(wtmp,length(wtmp)/3,3);
	end
	
	% Store event arrival times in waveform objects, then store the
	% waveforms in our big cell array eqwf.  There doesn't seem to be an
	% obvious way to vectorize these steps.
	% Also store other fields retrieved from database
	for na = 1:size(wtmp,1)
		wtmp(na,:) = addfield(wtmp(na,:),'EVENT_START',satimes(na));
		wtmp(na,:) = addfield(wtmp(na,:),'ETYPE',cell2mat(etype(eqindices(satime_indices(na),ns))));
 		wtmp(na,:) = addfield(wtmp(na,:),'ORID',orid(eqindices(satime_indices(na),ns)));
		wtmp(na,:) = addfield(wtmp(na,:),'OTIME',otime(eqindices(satime_indices(na),ns)));
		wtmp(na,:) = addfield(wtmp(na,:),'SEAZ',seaz(eqindices(satime_indices(na),ns)));

		% Technically, there can be a different signal type for each picked
		% arrival.  Here we make the assumption that the value of stype for
		% the chosen iphase (typically P) applies to all components.  This
		% will need to be kept in mind if developing a classification
		% routine that makes use of stype, and training catalogues designed
		% accordingly.
		wtmp(na,:) = addfield(wtmp(na,:),'STYPE',stype(eqindices(satime_indices(na),ns)));
		
		
		% Store waveforms in cell array.
		eqwf{satime_indices(na),ns} = wtmp(na,:);
	end
end

clear('wtmp'); % No longer needed so free up some space




%% Convert waveforms to threecomp objects where appropriate

% We've loaded all the waveforms.  Now convert the three-component sets
% into threecomp objects

fprintf(2,'Converting to threecomp objects if applicable...\n');

eqtc = cell(size(eqwf));
for no = 1:norigins
	for ns = 1:nstations
		if length(eqwf{no,ns}) == 3 % If it's three-compoenent
			eqtc{no,ns} = threecomp(eqwf{no,ns},eqtimes(no,ns));
		else % If it's 1-component (or empty)...
			eqtc{no,ns} = eqwf{no,ns}; % ...store the original value
		end
	end
end


%% Return eqwf if it was requested

if ret_eqwf
	varargout{1} = eqwf;
end

fprintf(2,'Done.\n');


end

