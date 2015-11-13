classdef antelopesource < dataretrieval.spatiotemporal_database
   %antelopesource Summary of this class goes here
   %   Detailed explanation goes here
   
   properties
      dbname = ''; %name of antelope database
      isopen = false; % status of antelope database
      searchcriteria % collection of search parameter strings to send to antelope
      chaninfo % array of channelTags
      startdate % one or more startdates
      enddate   % one or more enddates (matching # of startdate)
      dbpointer = []; % antelope database pointer
      filtereddb = []; % antelope database pointer (filtered)
      trpointer = { -1 }; % pointer to antelope trace
      applycalibrations = true; % apply calibration to tr before converting
      combinetraces = true;
      
   end
   
   properties(Dependent)
      nrecs  % number or records for current database ptr
      dbfields % field names for current database ptr
   end
   
   methods
      function p = get.dbfields(obj)
         try
            p = dbquery(obj.dbpointer,'dbTABLE_FIELDS');
         catch
            disp('unable to get fields');
            p = {};
         end
      end
      
      function tf = isdbfield(obj, candidate)
         %isdbfield   returns true if a string matches a current dbfieldname
         tf = ~isempty(candidate) && ismember(candidate, obj.fields );
      end
      
      function n = get.nrecs(obj)
         %nrecs   return either the number of records or 0
         try
            n = dbnrecs(obj.dbpointer);
         catch
            disp('unable to get nrecs');
            n = 0;
         end
      end
      
      function obj = open(obj, attrib)
         %open   open an antelope database to the wfdisc
         %   obj = open(obj, 'r') open antelope database for reading and
         %   sets the talbe to wfdisc
         if obj.isopen()
            error('the database might already be open');
         end
         try
            obj.dbptr = dbopen(obj.dbname, attrib);
            obj.isopen = true;
         catch er
            disp(er)
            error('Unable to open database');
         end
         try
            mydb = dblookup_table(mydb,'wfdisc');
         catch er
            disp(er)
            error('Able to open database, but not to open the wfdisc table');
         end
      end
      
      function obj = close(obj)
         %close   close an antelope database
         if obj.isopen()
            dbclose(obj.dbptr);
         else
            error('the database might already be closed');
         end
         obj.isopen = false;
      end
      
      function tf = pointsToAntelopeDatabase(obj)
         %pointsToAntelopeDatabase makes sure pointer points to valid db
         tf = ~isempty(obj.dbpointer) && ...
            isa(obj.dbpointer,'struct') && ...
            any(strcmpi(fieldnames(obj.dbpointer),'database'));
      end
      
      function data = retrieve(obj, where_, from_ , until_)
         assert(numel(datenum(from_)) == numel(datenum(until_)),...
            'Waveform:load_antelope:startEndMismatch', 'Unequal number of start and end times');
         obj.startdate = datenum(from_);
         obj.enddate = datenum(until_);
         error('unimplemented antelope data source');
      end
      
      outputWaveforms = load_antelope(request, specificDatabase)
      
      function outputWaveforms = RecursivelyLoadFromEachDatabase(request)
         TRY_MULTIDAY = false;
         database = getDatabase(request, TRY_MULTIDAY);
         database = unique(database, 'stable'); %  avoid changing requested order
         outputWaveforms = emptyWaveform();
         for n = 1 : numel(database)
            w = load_antelope(request, database(n));
            outputWaveforms = [outputWaveforms; w(:)]; %#ok<AGROW>
         end
      end
      
      function database = getDatabase(request, TRY_MULTIDAY)
         [ds, chanInfo, startTimes, endTimes] = unpackDataRequest(request);
         if TRY_MULTIDAY %good luck splicing
            dbDatesToCheck = subdivide_files_by_date(ds,startTimes, endTimes);
            database =  getfilename(ds,chanInfo, dbDatesToCheck);
         else
            database =  getfilename(ds,chanInfo, startTimes);
         end
      end
      
      function w = cycleThroughTraces(tr, COMBINE_WAVEFORMS)
         %cycleThroughTraces  converts each trace into one or more waveforms
         %   returns a Nx1 waveform
         w(numel(tr)).waves = waveform;
         for traceidx = 1:numel(tr)
            w(traceidx) = wavesfromtraces(tr, traceidx, COMBINE_WAVEFORMS);
         end
         w = [w.waves]; %horizontal cat
         w = w(:);
      end
      
      function w_scnl = wavesfromtraces(tr, traceidx, COMBINE_WAVEFORMS)
         if ~isstruct(tr{traceidx}) % marker for no data
            w_scnl.waves = emptyWaveform();
         else
            w_scnl.waves = traceToWaveform(tr{traceidx}); %create waveform list
            trdestroy(tr{traceidx});
         end
         if COMBINE_WAVEFORMS %combine all of this trace's records
            w_scnl.waves = combine(w_scnl.waves);
         end;
         w_scnl.waves = reshape(w_scnl.waves,  numel(w_scnl.waves), 1);
      end
      
      function obj = buildSearchCriteria(obj)
         %buildSearchCriteria creates searchstrings from chaninfo
         %
         % sample output for *.OKTU..EHZ :
         %         {'sta=~/OKTU/ && cha=~/EHZ/ && net=~/.*/'}
         
         for n=1:numel(obj.chaninfo)
            sc(n) = {buildSearchCriterion(obj.chaninfo(n))};
         end
         sc(cellfun(@isempty,sc))=[]; %remove empty values
         obj.searchcriteria = sc;
         
         function sc = buildSearchCriterion(chaninfo)
            sc = addto('','sta',chaninfo.station);
            sc = addto(sc,'chan',chaninfo.channel);
            sc = addto(sc,'net',chaninfo.network);
            sc = addto(sc,'loc',chaninfo.location);
         end
         
         function x = addto(x, fieldname, value)
            %addto   appends ' && fieldname=/value/' to x
            if ~isempty(value)
               if ~isempty(x); x = [x ' && ']; end
               value = replaceStars(value);
               x = [x, fieldname, '=~/', value,'/'];
            end
         end
         
         function value = replaceStars(value)
            %replaceStars   replace * with .*, but leave existing .* alone
            value = regexprep(value,'(?<!\.)\*','\.\*');
         end
      end
      
      [tr, rawDb, filteredDb] =  get_antelope_traces(obj, startdates, enddates, criteriaList, database)
      
   end
   methods(Static, Access=protected)
      [units, data_description] = segtype2units(unitCode)
      
      function w = emptyWaveform()
         %emptyWaveform   create an empty waveform
         w = waveform;
         w = w([]);
      end
      
      function w = blankWaveformWithCalib()
         %blankWaveformWithCalib   get blank waveform with default calib
         persistent wBlank
         if numel(wBlank) == 0  % cannot simply test if wBlank is empty
            wBlank = waveform;
            wBlank =  addfield(wBlank,'calib', 0);
            wBlank = addfield(wBlank, 'calibration_applied', 'NO');
         end
         w = wBlank;
      end
      
      function X = makecell(X)
         %makecell   ensure value is a cell, if not make it
         if ~iscell(X)
            X = {X};
         end
      end
      
   end
   
end
