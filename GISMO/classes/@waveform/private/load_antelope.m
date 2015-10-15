function outputWaveforms = load_antelope(request, specificDatabase)
   % load a waveform from antelope
   %  w = load_antelope(request, specificDatabase)
   %   CRITERIA is the search criteria, created with buildAntelopeCriteria
   %   request.sTime is the startTimes
   %   endTimes is the endTimes
   %   combineWaves is a logical value:
   %     Should segmented waveforms be combined,(within requested timerange)?
   %   database is the antelope database
   
   % AUTHOR: Celso Reyes
   % MODIFICATIONS: Glenn Thompson, Carl Tape
   
   
   %TODO: maybe order of operations can be changed to avoid unpacking
   %request when unnecessary.
   TRY_MULTIDAY = false;
   wBlank = waveform;
   wEmpty = wBlank([]);
   [ds, chanInfo, startTimes, endTimes, combineWaves] = unpackDataRequest(request);
   assert(numel(startTimes) == numel(endTimes),...
      'Waveform:load_antelope:startEndMismatch', 'Unequal number of start and end times');
   
   [criteria, nCriteria] = buildAntelopeCriteria(chanInfo);
   database =  getfilename(ds,chanInfo, startTimes);
   
   if TRY_MULTIDAY
      % the next 2 lines enable multiday data retrieval. However, splicing them may be tricky.
      dbDatesToCheck = subdivide_files_by_date(ds,startTimes, endTimes); %#ok<UNRCH>
      database =  getfilename(ds,chanInfo, dbDatesToCheck);
   end
   
   %for multiple databases, call this routine for each one, then return the waveforms.
   if ~exist('specificDatabase','var')
      % [~,inds] = unique(database); database = database(sort(inds)); % no longer necessary as of r2012a
      database = unique(database, 'stable'); %  avoid changing requested order
      antelope_load_fn = @(oneDB) load_antelope(request, oneDB);
      outputWaveforms = cellfun(antelope_load_fn, database, 'uniformOutput',false); % each cell
      outputWaveforms = transpose(vertcat(outputWaveforms{:}));
      return;
   end
   
   database = specificDatabase;
   
   outputWaveforms = wEmpty;
   for i = 1:nCriteria
      %if multiple traces will result, then there may be multiple records for tr
      [tr, database, fdb] = get_antelope_traces(...
         startTimes,endTimes,criteria(i).group, database);
      w = cycleThroughTraces(tr, combineWaves);
      %one tr exists for each timerequest within each scnl.
      outputWaveforms = [outputWaveforms; [w.waves]']; %#ok<AGROW>
   end
   dbclose(fdb);
end

function w = cycleThroughTraces(tr, COMBINE_WAVEFORMS)
   w(numel(tr)).waves = waveform;
   for traceidx = 1:numel(tr)
      w(traceidx) = wavesfromtraces(tr, traceindex, COMBINE_WAVEFORMS);
   end
end

function w_scnl = wavesfromtraces(tr, traceidx, COMBINE_WAVEFORMS)
   if ~isstruct(tr{traceidx}) % marker for no data
      wBlank = waveform;
      w_scnl.waves = wBlank([]);
   else
      w_scnl.waves = traceToWaveform(tr{traceidx}); %create waveform list
      trdestroy(tr{traceidx});
   end
   if COMBINE_WAVEFORMS && numel(w_scnl.waves) > 1, %combine all of this trace's records
      w_scnl.waves = combine(w_scnl.waves);
   end;
   w_scnl.waves = reshape(w_scnl.waves, 1, numel(w_scnl.waves));
end
   
%% helper functions

function [critList, nCrit] = buildAntelopeCriteria(chanTag)
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
   
   for N = numel(chanTag) : -1: 1
      critList(N).group(1) = grabCritList('sta', chanTag(N).station);
      critList(N).group(2) = grabCritList('net', chanTag(N).network);
      critList(N).group(3) = grabCritList('chan', chanTag(N).channel);
      critList(N).group(4) = grabCritList('loc', chanTag(N).location);
   end
   
   critList.statment =  {}; % PERHAPS UNUSED? CERTAINLY MISSPELLED.
   sta_crit = grabCritList('sta', chanTag.station); % struct with (field, relationship, data)
   cha_crit = grabCritList('chan', chanTag.channel);
   net_crit = grabCritList('net', chanTag.network); % expecting only 1
   loc_crit = grabCritList('loc', chanTag.location); % expecting only 1
   
   for i=1:numel(sta_crit)
      critList(i).group(1) = sta_crit(i);
      critList(i).group(2) = cha_crit(i);
      if ~isempty(net_crit), critList(i).group(end + 1) = net_crit; end;
      if ~isempty(loc_crit), critList(i).group(end + 1) = loc_crit; end;
   end
   
   critList = critList(:);
   nCrit = numel(critList);
end

function A = grabCritList(key, value)
   if ~isempty(value)
      value = regexprep(value,'(?<!\.)\*','\.\*'); %replace * with .*, but leave existing .* alone
      value = makecell(value);
      for i = numel(value) : -1 : 1
         A(i).field = key;
         A(i).relationship = '=~';
         A(i).value = value{i};
      end
   elseif ismember(key,{'sta','cha'})  %ew. get rid of special treatment
      erid = sprintf('Waveform:load_antelope:no%sTerm',key);
      error(erid,'No %s  requested. To retrieve all %ss use ''*''', key, key);
   else
      A = [];
   end
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
   
   % Modifications
   %%% Glenn Thompson 2012/02/06: Occasionally the C program trload_css cannot even load the trace data. Added try...catch..end to handle this.
   
   useExistingDatabasePtr =  isAntelopeDatabasePtr(database);
   
   if useExistingDatabasePtr
      try
         dbnrecs(database);
      catch
         warning('Waveform:load_antelope:databaseNotOpen', ...
            'a Database Pointer was passed to trace, but the database was not open');
         %tr = trnew; %return a new object, forcing the ability to destroy it later
         tr = { -1 };
         return;
      end
   end
   
   % do not close the database if a pointer is asked for in the return arguments
   onFinishCloseDB = nargout < 2;
   
   antelope_starts = mep2dep(startdates);
   antelope_ends = mep2dep(enddates);
   
   %if the database isn't already open, then open it for reading
   if ~useExistingDatabasePtr
      mydb = dbopen(database,'r');
      mydb = dblookup_table(mydb,'wfdisc');
   else
      mydb = database;
   end
   %check to ensure wfdisk table exists and is populated
   
   if safe_dbnrecs(mydb) == 0,
      cleanUpFail('Waveform:load_antelope:databaseNotFound', ...
         'Database not found: %s', dbquery(mydb,'dbTABLE_FILENAME'));
      return;
   end;
   
   rawDb = mydb;   % keep a copy of the pre-subset (raw) database
   
   % subset the data based upon the desired criteria
   
   dbFields = dbquery(mydb, 'dbTABLE_FIELDS');
   critFields = {criteriaList.field};
   % ensure criteria matches a field in the database
   criteriaList = criteriaList(ismember(critFields, dbFields));
   allExp = getAsExpressions(criteriaList);
      
   %subset the database based on this particular criterion
   mydb = dbsubset(mydb,allExp);
   if safe_dbnrecs(mydb) == 0
      cleanUpFail('Waveform:load_antelope:dataNotFound', 'No records found for criteria [%s].', allExp);
      return;
   end;
   
   filteredDb = mydb;
   
   [st, ed] = dbgetv(mydb,'time','endtime');
   %% Get the tracebuf object for this starttime, endtime
   % Loop through all times.  Result is tr(1:numel(starttimes) of all tracebuffers.
   for mytimeIDX = 1:numel(antelope_starts)
      someDataExists = any(antelope_starts(mytimeIDX)<= (ed) & antelope_ends(mytimeIDX) >= (st));
      if someDataExists
         %%% Glenn Thompson 2012/02/06: Occasionally the C program trload_css cannot even load the trace data.
         % This error needs to be handled. So adding a try..catch..end around the original instruction.
         try
            tr{mytimeIDX} = trload_css(mydb, antelope_starts(mytimeIDX), antelope_ends(mytimeIDX)); %#ok<AGROW>
         catch
            cleanUpFail('Waveform:load_antelope:trload_css failed', ...
               'Database not found: %s', dbquery(mydb,'dbTABLE_FILENAME'));
            disp(database)
            disp(allExp)
            starttimes = antelope_starts(mytimeIDX);
            endtimes = antelope_ends(mytimeIDX);
            fprintf('%.0f %.0f\n ',starttimes,endtimes);
            disp(['starttimes: ', datestr(epoch2datenum(starttimes))]);
            disp(['endtimes: ', datestr(epoch2datenum(endtimes))]);
            fprintf('trload_css(mydb, starttimes, endtimes))\n');
            return
         end
         trsplice(tr{mytimeIDX},20);
      else
         tr{mytimeIDX} = -1; %#ok<AGROW>
      end
   end %mytimeIDX
   closeIfAppropriate(mydb, onFinishCloseDB);
   
   function cleanUpFail(varargin)
      % tidy up database and records and display warning
      closeIfAppropriate(mydb, onFinishCloseDB);
      tr = { -1 };
      filteredDb = dbinvalid;
      warning(varargin{:});      
   end
end

function allExp = getAsExpressions(criteria)
   eachExp = arrayfun(crit2expression, criteria);
   allExp = eachExp{1};
   for i= 2 : (numel(eachExp))
      allExp = [allExp,' && ', eachExp{i}]; %#ok<AGROW>
   end
end

function cle = crit2expression(cl)
   if ischar(cl.data)
      cle = {sprintf('%s%s/%s/',cl.field, cl.relationship, cl.data)};
   else
      cle =  {sprintf('%s %s %s',cl.field,cl.relationship,num2str(cl.data))};
   end
end


function n = safe_dbnrecs(mydb)
   try
      n = dbnrecs(mydb);
   catch
      n = 0;
   end
end

function closeIfAppropriate(mydb, closeDatabase)
   if closeDatabase
      dbclose(mydb);
   end
end

function result = isAntelopeDatabasePtr(database)
   result = isa(database,'struct');
   result = result && any(strcmpi(fieldnames(database),'database'));
end

function X = makecell(X)
   if ~iscell(X)
      X = {X};
   end
end

function allw = traceToWaveform(tr)
   % TRACETOWAVEFORM converts traceobjects to waveforms
   %    w = traceToWaveform(blankwaveform, all_tracobjects)
   %
   % Note: this may return multiple waveform objects, depending upon
   % how many segments and/or scnl's.
   
   persistent wBlank           % cannot test if wBlank is empty because
   persistent blankWaveExists  %   isempty(wBlank) is always true.
   
   if isempty(blankWaveExists)
      wBlank = waveform;
      wBlank =  addfield(wBlank,'calib', 0);
      wBlank = addfield(wBlank, 'calibration_applied', 'NO');
      blankWaveExists = true;
   end
   
   try
      traceCount = dbnrecs(tr);
      assert(traceCount > 0);
   catch
      allw = wBlank([]);
      return
   end
   
   % preallocations
   spikes(traceCount).mask = false; %used to track data spikes & inf values
   allw = repmat(wBlank,traceCount,1);
   
   maxAllowableSignal = (realmax('single') * 1e-2);
   
   % LOOP twice through segments represented by this trace object
   % 1st loop: find signal spikes, and get header info.
   for seg = 1:traceCount
      tr.record = seg - 1;
      s = db2struct(tr); %do once, get one for each segment 
      [sunit, ~] = segtype2units(s.segtype);
      allw(seg) = set(wBlank, ...
         'station', s.sta, ...
         'channel', s.chan, ...
         'network', s.net, ...
         ... 'location', s.loc, ... % unknown if 'loc' really is a field
         'start', dep2mep(s.time), ...
         'freq', s.samprate, ...
         'units', sunit, ...
         'calib', s.calib);
      
      % data spikes must be known PRIOR to applying calibration
      data = trextract_data(tr);
      spikes(seg).mask =(abs(data) >= maxAllowableSignal) | isinf(data);
   end
   
   % now, apply calibrations to all traces at once
   trapply_calib(tr);
   hasCalibs = get(allw,'calib') ~= 0;
   allw(hasCalibs) = set(allw(hasCalibs),'calibration_applied','YES');
   
   % 2nd loop: assign data to the waveforms.
   replaceWithNan = @(W,BAD) setsamples(W, BAD.mask, nan);
   for seg = 1:traceCount
      tr.record = seg - 1;
      allw(seg) = set(allw(seg), 'data', trextract_data(tr));
      allw(seg) = replaceWithNan(allw(seg), spikes(seg));
   end
end

function [units, data_type] = segtype2units(segtype)
   %'segtype' in antelope datasets indicate the natural units of the detector
   persistent segUnits
   if isempty(segUnits)
      segUnits = getSegUnits();
   end
   if segUnits.isKey(segtype)
      details = segUnits(segtype);
      units = details{1};
      data_type = details{2};
   else
      [units, data_type] = deal('null');
   end
   
   function SU = getSegUnits()
      SU = containers.Map;
      %  segtype = {units , data_type}
      SU('A') = {'nm / sec / sec','acceleration'};
      SU('B') = {'25 mw / m / m','UV (sunburn) index(NOAA)'};
      SU('D') = {'nm', 'displacement'};
      SU('H') = {'Pa','hydroacoustic'};
      SU('I') = {'Pa','infrasound'};
      SU('J') = {'watts','power (Joulses/sec) (UCSD)'};
      SU('K') = {'kPa','generic pressure (UCSB)'};
      SU('M') = {'mm','Wood-Anderson drum recorder'};
      SU('P') = {'mb','barometric pressure'};
      SU('R') = {'mm','rain fall (UCSD)'};
      SU('S') = {'nm / m','strain'};
      SU('T') = {'sec','time'};
      SU('V') = {'nm / sec','velocity'};
      SU('W') = {'watts / m / m', 'insolation'};
      SU('a') = {'deg', 'azimuth'};
      SU('b') = {'bits/ sec', 'bit rate'};
      SU('c') = {'counts', 'dimensionless integer'};
      SU('d') = {'m', 'depth or height (e.g., water)'};
      SU('f') = {'micromoles / sec / m /m', 'photoactive radiation flux'};
      SU('h') = {'pH','hydrogen ion concentration'};
      SU('i') = {'amp','electric curent'};
      SU('m') = {'bitmap','dimensionless bitmap'};
      SU('n') = {'nanoradians','angle (tilt)'};
      SU('o') = {'mg/l','diliution of oxygen (Mark VanScoy)'};
      SU('p') = {'percent','percentage'};
      SU('r') = {'in','rainfall (UCSD)'};
      SU('s') = {'m / sec', 'speed (e.g., wind)'};
      SU('t') = {'C','temperature'};
      SU('u') = {'microsiemens/cm','conductivity'};
      SU('v') = {'volts','electric potential'};
      SU('w') = {'rad / sec', 'rotation rate'};
      SU('-') = {'null','null'};
   end
end
