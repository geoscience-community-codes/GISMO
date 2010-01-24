function outputWaveforms = load_antelope(datarequest, COMBINE_WAVEFORMS, specificDatabase)
% load a waveform from antelope
%  w = load_antelope(datarequest, COMBINE_WAVEFORMS, specificDatabase)
%   CRITERIA is the search criteria, created with buildAntelopeCriteria
%   sTime is the startTimes
%   datarequest.endTimes is the endTimes
%   COMBINE_WAVEFORMS is a logical value: 
%     Should segmented waveforms be combined,(within requested timerange)?
%   database is the antelope database

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 11/24/2009

%create a generic 1x1 and 0x0 waveforms for later use, so that the
%constructor does not constantly need to be called
blankWave = waveform;
emptyWave = blankWave([]);

%COMBINE_WAVEFORMS = false;

ensureAntelopeInstalled();
ensureEqualNumberOfStartAndEndTimes(datarequest);

criteria = buildAntelopeCriteria(datarequest.scnls);
nCriteria = numel(criteria);
database_dates_to_check = subdivide_files_by_date( ...
  datarequest.dataSource,...
  datarequest.startTimes,...
  datarequest.endTimes);

database =  getfilename(datarequest.dataSource,datarequest.scnls, datarequest.startTimes);

% the following line will enable the retrieval of multiple days worth of
% data all at once.  however, splicing them together may be tricky.
%database =  getfilename(datarequest.dataSource,datarequest.scnls, database_dates_to_check);

%if we have multiple databases to look in, then call this routine for each
%one, then return the resulting waveforms.
if ~exist('specificDatabase','var')
  database = unique(database);
  outputWaveforms = cell(size(database)); %preallocate
  for thisdatabaseN = 1 : numel(database)
    outputWaveforms(thisdatabaseN) = {load_antelope(datarequest, COMBINE_WAVEFORMS, database{thisdatabaseN})};
  end
  outputWaveforms = [outputWaveforms{:}];
  return;
end

database = specificDatabase;


outputWaveforms = emptyWave;
for i = 1:nCriteria
  %if multiple traces will result, then there may be multiple records for tr
  [tr, database, fdb] = ...
    get_antelope_traces(datarequest.startTimes,datarequest.endTimes,criteria(i).group, database);
  %one tr exists for each timerequest within each scnl.
  w(numel(tr)).waves = blankWave;
  for traceidx = 1:numel(tr)
    w_scnl = traceToWaveform(blankWave,tr(traceidx)); %create waveform list
    if COMBINE_WAVEFORMS && numel(w_scnl) > 1, %combine all of this trace's records
      w_scnl = combine(w_scnl);
    end;
    w(traceidx).waves = w_scnl(:)';
    clear w_scnl;
    trdestroy(tr(traceidx));
  end
  outputWaveforms = [outputWaveforms; [w.waves]'];
  clear w
end

dbclose(fdb);

%% helper functions

function critList = buildAntelopeCriteria(scnl)
% builds a criteria list from SCNL (Station-Channel-Network-Location)
% returns a structure array of cells with criteria for use with get_antelope_trace
% structure returned as critList(n).group, where group is a cell containing
% the criteria, such as {'sta == "OKCF"','chan=="EHZ"'}
%
% ex. myscnls = scnlobject({'OKCF','OKFG','OKSO'},{'EHZ','BHZ','BHZ'});
% ex.  cl =
% builtAntelopeCriteria(myscnls)
% ... CL will then contain
%
% CL(1).group(1).field = 'sta'
% CL(1).group(1).relation = '=='
% CL(1).group(1).data = 'OKCF'
% CL(1).group(2).field = 'chan'
% CL(1).group(2).relation = '=='
% CL(1).group(2).data = 'EHZ'
% ...
% CL(N).group(4).field = 'loc'
% CL(N).group(4).relation = '=='
% CL(N).group(4).data = '--'
%
% so...    getCritListExpression(CL(1).group(1)) --> 'sta == "OKCF"'
% It was done this way so that the dabase could be checked to ensure
% that the view actually supports each search parameter.
%
% either multiple stations OR multiple channels may work... not both.
% also, if any of the SCNL parameters are left empty, they will not be used
% in subsetting the antelope database.
%

station = get(scnl,'station');
channel = get(scnl,'channel');
network = get(scnl,'network');
location = get(scnl,'location');

critList.statment =  {};
if exist('station','var') && ~isempty(station)
  station = makecell(station);
  for i=1:numel(station)
    sta_crit(i) = makeCritListItem('sta','==',station{i});
  end
else
  sta_crit = {};
end

if exist('channel','var') && ~isempty(channel)
  channel = makecell(channel);
  for i=1:numel(channel)
    cha_crit(i) = makeCritListItem('chan','==',channel{i});
  end
else
  cha_crit = {};
end

for i=1:numel(sta_crit)
  critList(i).group(1) = sta_crit(i);
  critList(i).group(2) = cha_crit(i);
end


if ~isempty(network)
  network = makecell(network);
  for i=1:numel(critList)
    critList(i).group(end+1) = makeCritListItem('net','==',network{i});
  end
end

if ~isempty(location)
  location = makecell(location);
  for i=1:numel(critList)
    critList(i).group(end+1) = makeCritListItem('loc','==',location{i}); %#ok<*AGROW>
  end
end
critList = critList(:);

function cl = makeCritListItem(field, relationship, data)
cl.field = field;
cl.relationship = relationship;
cl.data = data;

function cle = getCritListExpression(cl)
switch class(cl.data)
  case('char')
    cle = sprintf('%s %s "%s"',cl.field, cl.relationship, cl.data);
  otherwise
    cle =  sprintf('%s %s %s',cl.field,cl.relationship,num2str(cl.data));
end

function [tr, rawDb, filteredDb] =  get_antelope_traces(startdates, enddates, criteriaList, database)
% GET_ANTELOPE_TRACE gets interesting data from database, and returns the tracebuf object
% [tr(1:end)] =  get_antelope_trace(startdates, enddates, criteriaList, database)
%    STARTDATE is a matlab datenum
%    ENDDATE is also in matlab datenum
%    CRITERIALIST is a cell of statements used to filter the antelope
%        database.  example: {'sta=="OKCF"','chan=="BHZ"'}
%    DATABASE can either be a database name, or an open antelope database
%    pointer.
%
%    TR is a tracebuf object containing the data requested.
%
%  In this usage, with a single output argument, TR, the database is opened
%  and then closed before the function returns.
%
% You can opt to keep the database open, which can make subsequent calls to
% get_antelope_trace much faster.  To do this, ask for the database pointer
% as one of the output arguments.  The database will be closed by any
% function call that uses the database pointer as the 'database' parameter,
% and does not ask for a database pointer back.
%
% [tr, mydb] = get_antelope_trace(...)
%    if mydb is asked for, then the database will not be closed, allowing for
%    more efficient reuse.  mydb is the unfiltered (and open) wfdisc table
%
% [tr, mydb, filteredDB] = get_antelope_trace(...)
%   returns wfdisc table in mydb, and a filtered wfdisc table in filteredDB
%
% if no records are found, then tr will be set to []
%
% will generate error message if no records found, so consider using in a
% TRY-CATCH loop.
%
%
% Example:
%  % set up the data
%  sDate = datenum('7/12/2008 05:00:00.00');
%  eDate = datenum('7/12/2008 05:10:00.00');
%  stationsToGet = {'OKFG','OKSO','OMG'};
%  channelsToGet = {'BHZ', 'BHE'};
%  mydb = '/mydir/my_antelope_database';
%
%  % get our criteria together
%  for st = 1:numel(stationsToGet)
%    staCriteria(st) = {sprintf('sta=="%s"',stationsToGet(st)};
%  end
%  for ch = 1:numel(channelsToGet)
%    chanCriteria(ch) = {sprintf('chan=="%s"',channelsToGet(ch)};
%  end
%
%  % open the database once, and read in each tracebuf. Then translate into
%  % waveforms.
%  n = 1;
%  for sta = 1:numel(staCriteria)
%    for ch = 1:numel(chanCriteria)
%      critera = [chanCriteria(ch),staCriteria(sta)];
%      [tr, mydb] = get_antelope_trace(sDate,eDate, criteria, mydb)
%      w(n) = traceToWaveform(tr);
%      n = n+1;
%    end
%  end
%  % finally, close up shop.
%  dbclose(mydb)

global mep2dep

useExistingDatabasePtr =  isAntelopeDatabasePtr(database);

if useExistingDatabasePtr
  try
    dbnrecs(database);
  catch
    warning('Waveform:load_antelope:databaseNotOpen', ...
      'a Database Pointer was passed to trace, but the database was not open');
    tr = trnew; %return a new object, forcing the ability to destroy it later
    return;
  end
end

% do not close the database if a pointer is asked for in the return
% arguments
closeDatabaseWhenDone = nargout < 2;


antelope_starts = mep2dep(startdates);
antelope_ends = mep2dep(enddates);

%if the database isn't already open, then open it for reading
if ~useExistingDatabasePtr
  mydb = dbopen(database,'r');
  mydb = dblookup_table(mydb,'wfdisc');
else
  mydb = database;
end
try
  nrecs = dbnrecs(mydb);
catch
  nrecs = 0;
end
%check to ensure wfdisk table exists and is populated
if nrecs == 0,
  closeIfAppropriate(mydb);
  warning('Waveform:load_antelope:databaseNotFound', ...
    'Database not found: %s', databaseFileName);
  tr = trnew; filteredDb = dbinvalid;
  return;
end;

%keep a copy of the pre-subset (raw) database
rawDb = mydb;

% subset the data based upon the desired criteria
listOfDBFields = dbquery(mydb, 'dbTABLE_FIELDS');
% check to ensure criteria matches a field in the database
criteriaList = criteriaList(ismember({criteriaList.field},listOfDBFields));
for i=1:numel(criteriaList)
  expList(i) = {getCritListExpression(criteriaList(i))};
end
allExp = expList{1};
for i=2: (numel(expList))
  allExp = [allExp,' && ', expList{i}];
end

%subset the database based on this particular criterion
mydb = dbsubset(mydb,allExp);
try
  nrecs = dbnrecs(mydb);
catch
  nrecs = 0;
end
if nrecs == 0
  closeIfAppropriate(mydb);
  warning('Waveform:load_antelope:dataNotFound', ...
    'No records found for criteria [%s].', allExp);
  tr = trnew;
  filteredDb = dbinvalid;
  return;
end;

filteredDb = mydb;

[st, ed] = dbgetv(mydb,'time','endtime');
%% Get the tracebuf object for this starttime, endtime
% Loop through all times.  Result is tr(1:numel(starttimes) of all tracebuffers.
for mytimeIDX = 1:numel(antelope_starts)
  someDataExists = any(antelope_starts(mytimeIDX)<= (ed) & antelope_ends(mytimeIDX) >= (st));
  if someDataExists
    tr(mytimeIDX) = trload_css(mydb, antelope_starts(mytimeIDX), antelope_ends(mytimeIDX));
    trsplice(tr(mytimeIDX),20);
  else
    tr(mytimeIDX) = trnew;
  end
end %mytimeIDX
closeIfAppropriate(mydb);

function closeIfAppropriate(mydb)
closeDatabase = evalin('caller','closeDatabaseWhenDone');
if closeDatabase
  dbclose(mydb);
end

function result = isAntelopeDatabasePtr(database)
result = false;
if ~isa(database,'struct')
  return
end
fn =  fieldnames(database);
if ~any(strcmpi(fn,'database'))
  return
end
result = true;
function outcell = makecell(inVar)
if ~iscell(inVar)
  outcell = {inVar};
else
  outcell = inVar;
end

function allw = traceToWaveform(blankw,tr)
% TRACETOWAVEFORM converts traceobjects to waveforms
%    w = traceToWaveform(blankwaveform, all_tracobjects,[units])
%
% Note: this may return multiple waveform objects, depending upon
% how many segments and/or scnl's.
%
global dep2mep
% try to end up with a single waveform object
try
  traceCount = dbnrecs(tr);
catch
  allw = blankw([]);
  return
end
if traceCount == 0
  %no records!
  allw = blankw([]);
  return
end

%badmask contains the location of data spikes and infinite values.
badmask(traceCount).mask = 0; %preallocate
allw = repmat(blankw,traceCount,1); %preallocatewithout calling constructor

maxAllowableSignal = (realmax('single') * 1e-2);

% LOOP twice through segments represented by this trace object
% the first time, find out where signal is good or bad, and flesh out the
% header information.
% Then, apply the calibration and loop through a second time, assigning the
% data to the waveforms.

for seg = 1:traceCount
  % units is now a cell
  tr.record = seg - 1;
  s = db2struct(tr); %do once, get one for each segment
  
  tempw = set(allw(seg),'station',s.sta,'channel',s.chan,'start', dep2mep(s.time),'freq',s.samprate,'nohist');
  % s(seg).loc doesn't exist... allw(seg) = addfield(allw(seg),'loc',s(seg).loc);
  tempw = addfield(tempw,'calibration_applied','NO','nohist');
  sunit = segtype2units(s.segtype); %not bothering to get the unit detail
  tempw = set(tempw,'units',sunit,'nohist');
  allw(seg) = addfield(tempw,'calib',s.calib,'nohist');
  a = trextract_data(tr);
  %get rid of dataspikes
  badmask(seg).mask =(abs(a) >= maxAllowableSignal) | isinf(a);
end

trapply_calib(tr);

validCalibs = hasValidCalib(allw);
allw(validCalibs) = set(allw(validCalibs),'calibration_applied','YES');
for seg = 1:traceCount
  tr.record = seg - 1;
  a = trextract_data(tr);
  a(badmask(seg).mask) = nan;
  allw(seg) = set(allw(seg),'data',a,'nohist');
end

function validCalibMask = hasValidCalib(w)
validCalibMask = get(w,'calib') ~= 0;

function [units, type_of_data] = segtype2units(segtype)
%'segtype' in antelope datasets indicate the natural units of the detector
segTypes = 'ABDHIJKMPRSTVWabcdfhimnoprstuvw-';
segUnits = {'A','nm / sec / sec','acceleration';
  'B', '25 mw / m / m','UV (sunburn) index(NOAA)';
  'D', 'nm', 'displacement';
  'H','Pa','hydroacoustic';
  'I','Pa','infrasound';
  'J','watts','power (Joulses/sec) (UCSD)';
  'K','kPa','generic pressure (UCSB)';
  'M','mm','Wood-Anderson drum recorder';
  'P','mb','barometric pressure';
  'R','mm','rain fall (UCSD)';
  'S','nm / m','strain';
  'T','sec','time';
  'V','nm / sec','velocity';
  'W','watts / m / m', 'insolation';
  'a','deg', 'azimuth'
  'b','bits/ sec', 'bit rate';
  'c','counts', 'dimensionless integer';
  'd','m', 'depth or height (e.g., water)';
  'f','micromoles / sec / m /m', 'photoactive radiation flux';
  'h','pH','hydrogen ion concentration';
  'i','amp','electric curent'
  'm','bitmap','dimensionless bitmap';
  'n','nanoradians','angle (tilt)';
  'o','mg/l','diliution of oxygen (Mark VanScoy)';
  'p','percent','percentage';
  'r','in','rainfall (UCSD)';
  's','m / sec', 'speed (e.g., wind)';
  't','C','temperature';
  'u','microsiemens/cm','conductivity';
  'v','volts','electric potential';
  'w','rad / sec', 'rotation rate';
  '-','null','null'};
if ~ismember(segtype,segTypes)
  segtype=  '-';
end
thisseg = find(segtype==segTypes);
units = segUnits{thisseg,2};
type_of_data = segUnits{thisseg,3};

function ensureAntelopeInstalled()
% errors out if antelope is not installed on the system.

%make sure antelope is in the path
%path_exists = ~isempty(findstr('/antlope',path));
path_exists = true;
% the old check involved looking for dbopen and trload_css

if ~path_exists
  error('Waveform:load_antelope:noAntelopeToolbox',...
    'It doesn''t appear that the antelope toolbox is available');
end

function ensureEqualNumberOfStartAndEndTimes(datarequest)
if numel(datarequest.startTimes) ~= numel(datarequest.endTimes)
  error('Waveform:load_antelope:startEndMismatch',...
    'unequal number of start and end times');
end
