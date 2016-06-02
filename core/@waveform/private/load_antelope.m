function outputWaveforms = load_antelope(request, specificDatabase)
   % load a waveform from antelope
   %
   % Warning: this method has been gutted & rebuilt by Glenn Thompson
   %    on 20160513 to fix an array of problematic test cases submitted by
   %    Carl Tape and Helena Buurman. In doing this, multiple
   %    startTimes/endTimes not yet resupported. Also waveforms will always
   %    be combined from trace segments, and padded (with NaNs to go from
   %    requested start to end time).
   %
   %  w = load_antelope(request, specificDatabase)
   %    request is a structure with arguments:
   %        dataSource
   %        chanInfo (type ChannelTag)
   %        startTimes
   %        endTimes
   %        combineWaves
   %
   %    specificDatabase gets populated if you call waveform with an
   %    explicit dbpath (rather than a datasource) - I think
   
   % AUTHOR: Glenn Thompson but lifting heavily from the original function 
   % by Celso Reyes. 
   
   % TODO: re-add support for multiple start/endtimes. Fragments of this
   % remain, which is why there is a loop in get_traces and why it returns
   % a cell array of waveforms.
   
   [~, chanInfo, startDatenums, endDatenums, combineWaves] = unpackDataRequest(request);
   assert(numel(startDatenums) == numel(endDatenums),...
      'Waveform:load_antelope:startEndMismatch', 'Unequal number of start and end times');
  
  if numel(startDatenums)~=1
      warning('Sorry, in the modified version of waveform/load_antelope, multiple start/endtimes not supported. If you need this feature email Glenn Thompson');
      outputWaveforms = emptyWaveform();
      return
  end
      
   % call this routine for each database, then return the waveforms.
   if exist('specificDatabase','var') % called with a specific database, not a datasource
       % but may be a nested call from a datasource using RecursivelyLoadFromEachDatabase()
      database = specificDatabase;
      outputWaveforms = emptyWaveform();
      
      % Glenn 2016/05/12 Check if wfdisc table exists
      
      % Glenn 2016/05/12 Build expressions here for subsetting database
      % station or channel may have a wildcard, but not both
      % need to expand this wildcard
      
      % get sta and chan cell arrays (same length)
      if isa(chanInfo, 'ChannelTag')
            sta = {chanInfo.station};
            chan = {chanInfo.channel};
      elseif isa(chanInfo, 'scnlobject')
            sta = get(scnl, 'station');
            chan = get(scnl, 'channel');
      else
          error('variable chanInfo is of unknown type')
      end
      
      % seems like sta and chan always returned as cell arrays
      stawildcard = false;
      chanwildcard = false;
      allsta = {};
      allchan = {};
      for stachannum = 1:numel(sta)
          
          thissta = sta{stachannum};
          thischan = chan{stachannum};
      
          % expand station wildcard
          if strfind(thissta,'*') 
             thissta = strrep(thissta, '*', '.*');
             stawildcard = true;
             % This code expands wildcard based on stations in wfdisc table
             stadb = dbopen(database,'r');
             stadb = dblookup_table(stadb,'wfdisc');
             stadb = dbsubset(stadb, sprintf('sta=~/%s/',thissta)); 
             thissta = unique(dbgetv(stadb,'sta'))';
             thissta(strncmp(thissta,'+',1)) = []; % get rid of stations beginning with "+"
             
             % SCAFFOLD: might need to close db here
          end

          % expand channel wildcard
          if strfind(thischan,'*')
             thischan = strrep(thischan, '*', '.*');
             chanwildcard = true;
             % This code expands wildcard based on channels in wfdisc table
             chandb = dbopen(database,'r');
             chandb = dblookup_table(chandb,'wfdisc');
             chandb = dbsubset(chandb, sprintf('chan=~/%s/',thischan)); 
             thischan = unique(dbgetv(chandb,'chan'))';
             
             % SCAFFOLD: might need to close db here
          end
      
          % Append the final list of stations and channels to all
          allsta = [allsta thissta];
          allchan = [allchan thischan];
          
          
      end
      
      % change variables back
      if stawildcard || chanwildcard
          sta = allsta;
          chan = allchan;
      end
      
      % create expression for station & channel combinations
      if numel(sta) == numel(chan)
          expr = '( ';
          for count=1:numel(sta)
              expr = [expr, sprintf('(sta=~/%s/ && chan=~/%s/)', sta{count}, chan{count})];
              if count<numel(sta)
                  expr = [expr,' || '];
              else
                  expr = [expr,' ) '];
              end
          end

      elseif numel(sta)==1
          expr = sprintf('sta=~/%s/ && (chan=~/',sta{1});
          for count=1:numel(chan)
              expr = [expr,chan{count}]; 
              if count<numel(chan)
                  expr = [expr,'|'];
              else
                  expr = [expr,'/) '];
              end
          end
      
      elseif numel(chan)==1
          expr = sprintf('chan=~/%s/ && (sta=~/',chan{1});
          for count=1:numel(sta)
              expr = [expr,sta{count}]; 
              if count<numel(sta)
                  expr = [expr,'|'];
              else
                  expr = [expr,'/) '];
              end
          end

      end
         
         
      % Glenn 2016/05/12 Get the trace objects
      [wcell, database, fdb] = get_traces(startDatenums, endDatenums, expr, database, combineWaves);
      w=wcell{:};
      
      % Glenn 2016/05/12 Close db if open
      if fdb.database ~= -102   % fdb ~= dbinvalid
            dbclose(fdb);
      end
      
      % Glenn 2016/05/12 finally ensure output order of waveform objects is
      % same as requested in list of sta/chan - add in blank waveform
      % objects where nothing exists
      
      
      if ~stawildcard & ~chanwildcard % return exactly the list asked for, include blank waveforms as necessary
      
          % make the sta and chan cells same size       
          if numel(sta)==1 && numel(chan)>1
              sta = cellstr(repmat(sta{1}, numel(chan), 1));
          end
          if numel(chan)==1 && numel(sta)>1
              chan = cellstr(repmat(chan{1}, numel(sta), 1));
          end      
          
          % second loop through them and attach appropriate waveform (or blank
          % waveform)
          for count1 = 1:numel(sta)
              ctag=ChannelTag('', sta{count1}, '', chan{count1});
              outputWaveforms(count1) = waveform(ctag, 0, startDatenums(1), [], '');
              for count2 = 1:numel(w)
                  wsta = get(w(count2),'station');
                  wchan = get(w(count2),'channel');
                  if strcmp(wsta, sta{count1}) & strncmp(wchan, chan{count1}, 3)
                      outputWaveforms(count1) = w(count2);
                      break;
                  end
              end
          end
      else
          outputWaveforms = w;
      end
      
      % Get calling function. 
      [ST,I] = dbstack();
      switch(ST(2).name)
          case 'RecursivelyLoadFromEachDatabase', debug.print_debug(1,'looping over multiple databases')
          otherwise % assume called with an explicit dbpath argument, which means need to combine and pad waveforms here
                outputWaveforms = combine(outputWaveforms);
                outputWaveforms = pad(outputWaveforms, request.startTimes(1), request.endTimes(1), NaN);    
      end

   else
      % called with a datasource argument 
      outputWaveforms = RecursivelyLoadFromEachDatabase(request);
   end
end

%%
function outputWaveforms = RecursivelyLoadFromEachDatabase(request)
   % when called with a datasource argument, this function is called
   
   % got to figure out which database to use
   TRY_MULTIDAY = false;
   TRY_MULTIDAY = true; % Glenn changed to true
   database = getDatabase(request, TRY_MULTIDAY);
   database = unique(database, 'stable'); %  avoid changing requested order
   outputWaveforms = emptyWaveform();
   for n = 1 : numel(database)
      w = load_antelope(request, database(n));
      outputWaveforms = [outputWaveforms; w(:)]; 
   end
   outputWaveforms = combine(outputWaveforms);
   outputWaveforms = pad(outputWaveforms, request.startTimes(1), request.endTimes(1), NaN);
end

%%
function w = emptyWaveform()
   w = waveform;
   w = w([]);
end

%%
function database = getDatabase(request, TRY_MULTIDAY)
   [ds, chanInfo, startDatenums, endDatenums] = unpackDataRequest(request);
   if TRY_MULTIDAY %good luck splicing
      dbDatesToCheck = subdivide_files_by_date(ds,startDatenums, endDatenums);
      database =  unique(getfilename(ds,chanInfo, dbDatesToCheck)); % Glenn added unique
   else
      database =  unique(getfilename(ds,chanInfo, startDatenums)); % Glenn added unique
   end
end

%%
function [w, rawDb, filteredDb] =  get_traces(startDatenums, endDatenums, expr, database, combineWaves)
   % GET_TRACES gets interesting data from database, and returns the tracebuf object
   % [tr(1:end)] =  get_antelope_trace(startDatenums, endDatenums, criteriaList, database)
   %    STARTDATE is a matlab datenum
   %    ENDDATE is also in matlab datenum
   %    EXPR is the expression list formed from the station & channel
   %    combinations
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
   % [tr, mydb] = get_traces(...)
   %    if mydb is asked for, then the database will not be closed, allowing for
   %    more efficient reuse.  mydb is the unfiltered (and open) wfdisc table
   %
   % [tr, mydb, filteredDB] = get_traces(...)
   %   returns wfdisc table in mydb, and a filtered wfdisc table in filteredDB
   %
   % if no records are found, then tr will be set to []
   %
   % will generate error message if no records found, so consider using in a
   % TRY-CATCH loop.
   %
   
   % Modifications
   %%% Glenn Thompson 2012/02/06: Occasionally the C program trload_css cannot even load the trace data. Added try...catch..end to handle this.
   
   w = {emptyWaveform()};
   
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
   
   start_epochs = mep2dep(startDatenums);
   end_epochs = mep2dep(endDatenums);
   
   %if the database isn't already open, then open it for reading
   if ~useExistingDatabasePtr
       if isa(database,'cell')
           for cc=1:numel(database)
                debug.print_debug(1,sprintf('database path = %s',database{cc}));
           end
       end
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
   
   %subset the database based on the station/channel expression
   debug.print_debug(1,sprintf('\nSubsetting wfdisc table with the following sta-chan subset expression:\n\t%s\n\n',expr));
   mydb = dbsubset(mydb,expr);
   if safe_dbnrecs(mydb) == 0
      cleanUpFail('Waveform:load_antelope:dataNotFound', 'No records found for criteria [%s].', expr);
      return;
   end

   filteredDb = mydb;
   
   [wfdisctime, wfdiscendtime] = dbgetv(mydb,'time','endtime');
   %% Get the tracebuf object for this starttime, endtime
   % Loop through all times.  Result is tr(1:numel(startDatenums) of all tracebuffers.
   for mytimeIDX = 1:numel(start_epochs)
      someDataExists = any(start_epochs(mytimeIDX)<= wfdiscendtime & end_epochs(mytimeIDX) >= wfdisctime);
     
      if someDataExists
          
         % time subset
         nbefore = safe_dbnrecs(mydb);
         expr_time = sprintf('time < %f  && endtime > %f ',end_epochs(mytimeIDX), start_epochs(mytimeIDX));
         dbptr = dbsubset(mydb, expr_time);

         % Display matching records
         if debug.get_debug()>0
             nnow = safe_dbnrecs(dbptr);
            fprintf('Found %d matching time records (had %d before time subset):',nnow,nbefore);
            for c=1:safe_dbnrecs(dbptr)
                dbptr.record = c-1;
                [wfid, sta, chan, wftime, wfendtime]=dbgetv(dbptr , 'wfid','sta','chan','time', 'endtime');
                fprintf('%12d %s %s %s %s\n',wfid, sta, chan, datestr(epoch2datenum(wftime)), datestr(epoch2datenum(wfendtime)));   
            end
         end

         %%% Glenn Thompson 2012/02/06: Occasionally the C program trload_css cannot even load the trace data.
         % This error needs to be handled. So adding a try..catch..end around the original instruction.
         try
            debug.print_debug(1,sprintf('\nTRYING TO LOAD TRACES FROM WHOLE WFDISC SUBSET IN ONE GO\n'));
            tr = trload_css(dbptr, start_epochs(mytimeIDX), end_epochs(mytimeIDX));
            trsplice(tr,20);            
            %st = tr2struct(tr)
            w0 = trace2waveform(tr);  % Glenn's simple method
            %w0 = traceToWaveform(tr);  % Celso's more sophisticated method
            %w0 = cycleThroughTraces(tr, combineWaves); % This is even more
            %sophisticated, and calls traceToWaveform and others, but
            %causes seg faults.
            trdestroy( tr );
         catch
                debug.print_debug(1,sprintf('\nBulk mode failed\nTRYING TO LOAD TRACES FROM ONE WFDISC ROW AT A TIME\n'));
                w0 = [];
                for c=1:safe_dbnrecs(dbptr)
                    dbptr.record = c-1;
                    wfid=dbgetv(dbptr, 'wfid');
                    dbptr_one_record = dbsubset(dbptr, sprintf('wfid==%d',wfid));
                    debug.print_debug(1,sprintf('Got %d matching records\n',safe_dbnrecs(dbptr_one_record )));
                    [wfid, sta, chan, st, et]=dbgetv(dbptr_one_record , 'wfid','sta','chan','time', 'endtime');
                    debug.print_debug(1,sprintf('%12d %s %s %f %f\n',wfid, sta, chan, st, et));
                    try
                        tr = trload_css(dbptr_one_record , start_epochs(mytimeIDX), end_epochs(mytimeIDX));
                        trsplice(tr,20);
                        w0 = [w0;trace2waveform(tr)];  % Glenn's simple method
                        %w0 = [w0;traceToWaveform(tr)];  % Celso's more sophisticated method
                        %w0 = [w0;cycleThroughTraces(tr, combineWaves)]; % This is even more
                        %sophisticated, and calls traceToWaveform and others, but
                        %causes seg faults.
                        trdestroy( tr );
                    catch ME
                        if strcmp(ME.identifier, 'MATLAB:unassignedOutputs')
                            % no trace table returned by trload_css
                            w0 = [w0; waveform(ChannelTag('',sta,'',chan), NaN, epoch2datenum(start_epochs(mytimeIDX)), [], '')];
                        else
                            rethrow(ME)
                        end
                    end
                    try
                        dbfree(dbptr_one_record )
                    catch ME
                        ME.identifier
                        rethrow ME
                    end     
                end             
         end
      else
         w0=waveform(); 
      end
      w{mytimeIDX} = combine(w0);
      %w{mytimeIDX} = pad(w{mytimeIDX}, startDatenums(mytimeIDX), endDatenums(mytimeIDX), NaN);
      %w{mytimeIDX} = w0;
      clear w0
   end %mytimeIDX
   closeIfAppropriate(mydb, onFinishCloseDB);
   
   function cleanUpFail(varargin)
      %cleanUpFail   tidy up database and records and display warning
      closeIfAppropriate(mydb, onFinishCloseDB);
      tr = { -1 };
      filteredDb = dbinvalid;
      warning(varargin{:});      
   end
end

%%
function w = trace2waveform(tr)
% Glenn 2016/05/13

   % apply calibrations to all traces at once - don't do this, turns all
   % calibs into 1
   %trapply_calib(tr);

    if debug.get_debug()>0
        fprintf('\n\nMatching trace objects are:\n');
    end

    % create empty waveform variables
    wt = repmat(waveform(),safe_dbnrecs(tr),1);

    % load data and metadata from trace table into waveform objects
    for cc=1:safe_dbnrecs(tr)
        tr.record = cc-1;
        [trnet, trsta, trchan, trtime, trendtime, trnsamp, trsamprate, trinstype, trcalib, trcalper, trresponse, trdatatype, trsegtype] = dbgetv(tr, 'net', 'sta', 'chan', 'time', 'endtime', 'nsamp', 'samprate','instype','calib','calper','response','datatype','segtype');
        trtime = epoch2datenum(trtime);
        trendtime = epoch2datenum(trendtime);
        trdata=trextract_data( tr );
        npts=length(trdata);
        if debug.get_debug() > 0
            fprintf('%s\t%s\t%s\t%s\t%d\t%f\t%d\n',trsta,trchan,datestr(trtime),datestr(trendtime),trnsamp,trsamprate,npts);       
        end
        if strcmp(trnet,'-')
            trnet='';
        end
        [trunits, ~] = segtype2units(trsegtype);
        wt(cc) = waveform(ChannelTag(trnet,trsta,'',trchan), trsamprate, trtime, trdata*trcalib, trunits);
        wt(cc) = addfield(wt(cc),'calib', trcalib);
        if trcalib~=0
            wt(cc) = addfield(wt(cc), 'calibration_applied', 'YES');
        else
            wt(cc) = addfield(wt(cc), 'calibration_applied', 'NO');
        end
    end
    w = combine(wt); % combine waveforms based on ChannelTag (I think)
    clear wt

end

%%
function [units, data_description] = segtype2units(unitCode)
   %segtype2units   retrieves unit and description based on the segtype code
   %'segtype' in antelope datasets indicate the natural units of the detector
   persistent codeKey
   if isempty(codeKey)
      codeKey = createCodeKey();
   end
   if codeKey.isKey(unitCode)
      details = codeKey(unitCode);
      units = details{1};
      data_description = details{2};
   else
      [units, data_description] = deal('null');
   end
   
   function SU = createCodeKey()
      %createSegUnits   creates a map  where SU(char) = {units, data_description}
      SU = containers.Map;
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

%%
function n = safe_dbnrecs(mydb)
   %safe_dbnrecs   return either the number of records or 0
   %   n = safe_dbnrecs(mydb)  when accessing dbnrecs fails, this returns 0
   try
      n = dbnrecs(mydb);
   catch
      n = 0;
   end
end

%%
function closeIfAppropriate(mydb, closeDatabase)
   if closeDatabase
      dbclose(mydb);
   end
end


%%
function result = isAntelopeDatabasePtr(database)
   result = isa(database,'struct');
   result = result && any(strcmpi(fieldnames(database),'database'));
end


%% obsolete methods

% function X = makecell(X)
%    if ~iscell(X)
%       X = {X};
%    end
% end
% 
% function allw = traceToWaveform(tr)
%    %traceToWaveform converts traceobjects to waveforms
%    %    w = traceToWaveform(blankwaveform, all_tracobjects)
%    %
%    % Note: this may return multiple waveform objects, depending upon
%    % how many segments and/or scnl's.
%    
%    persistent wBlank           % cannot test if wBlank is empty because
%    persistent blankWaveExists  %   isempty(wBlank) is always true.
%    
%    if isempty(blankWaveExists)
%       wBlank = waveform;
%       wBlank =  addfield(wBlank,'calib', 0);
%       wBlank = addfield(wBlank, 'calibration_applied', 'NO');
%       blankWaveExists = true;
%    end
%    
%    try
%       traceCount = dbnrecs(tr);
%       assert(traceCount > 0);
%    catch
%       allw = wBlank([]);
%       return
%    end
%    
%    % preallocations
%    spikes(traceCount).mask = false; %used to track data spikes & inf values
%    allw = repmat(wBlank,traceCount,1);
%    
%    maxAllowableSignal = (realmax('single') * 1e-2);
%    
%    % LOOP twice through segments represented by this trace object
%    % 1st loop: find signal spikes, and get header info.
%    for seg = 1:traceCount
%       tr.record = seg - 1;
%       s = db2struct(tr); %do once, get one for each segment 
%       [sunit, ~] = segtype2units(s.segtype);
%       allw(seg) = set(wBlank, ...
%          'station', s.sta, ...
%          'channel', s.chan, ...
%          'network', s.net, ...
%          ... 'location', s.loc, ... % unknown if 'loc' really is a field
%          'start', dep2mep(s.time), ...
%          'freq', s.samprate, ...
%          'units', sunit, ...
%          'calib', s.calib);
%       
%       % data spikes must be known PRIOR to applying calibration
%       data = trextract_data(tr);
%       spikes(seg).mask =(abs(data) >= maxAllowableSignal) | isinf(data);
%    end
%    
%    % now, apply calibrations to all traces at once
%    trapply_calib(tr);
%    hasCalibs = get(allw,'calib') ~= 0;
%    allw(hasCalibs) = set(allw(hasCalibs),'calibration_applied','YES');
%    
%    % 2nd loop: assign data to the waveforms.
%    replaceWithNan = @(W,BAD) setsamples(W, BAD.mask, nan);
%    for seg = 1:traceCount
%       tr.record = seg - 1;
%       allw(seg) = set(allw(seg), 'data', trextract_data(tr));
%       allw(seg) = replaceWithNan(allw(seg), spikes(seg));
%    end
% end
% 
% 
% function w = cycleThroughTraces(tr, COMBINE_WAVEFORMS)
%    if ~isa(tr,'cell')
%        tr={tr};
%    end
%    %cycleThroughTraces  converts each trace into one or more waveforms
%    %   returns a Nx1 waveform
%    w(numel(tr)).waves = waveform;
%    for traceidx = 1:numel(tr)
%       w(traceidx) = wavesfromtraces(tr, traceidx, COMBINE_WAVEFORMS);
%    end
%    w = [w.waves]; %horizontal cat
%    w = w(:);
% end
% 
% function w_scnl = wavesfromtraces(tr, traceidx, COMBINE_WAVEFORMS)
%    if ~isstruct(tr{traceidx}) % marker for no data
%       w_scnl.waves = emptyWaveform();
%    else
%       w_scnl.waves = traceToWaveform(tr{traceidx}); %create waveform list
%       trdestroy(tr{traceidx});
%    end
%    if COMBINE_WAVEFORMS %combine all of this trace's records
%       w_scnl.waves = combine(w_scnl.waves);
%    end;
%    w_scnl.waves = reshape(w_scnl.waves,  numel(w_scnl.waves), 1);
% end
% 
% 
