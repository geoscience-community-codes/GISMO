classdef antelopesource < dataretrieval.spatiotemporal_database
   %antelopesource Summary of this class goes here
   %   Detailed explanation goes here
   
   properties
      dbname = ''; %name of antelope database
      isopen = false; % status of antelope database
      searchcriteria % collection of search parameter strings to send to antelope
      chaninfo % array of channelTags
      matlabstart % one or more startdates (in matlab format)
      matlabend   % one or more enddates in matlab format (matching # of startdate)
      dbpointer = []; % antelope database pointer
      filtereddb = []; % antelope database pointer (filtered)
      trpointer = { -1 }; % pointer to antelope trace
      applycalibrations = true; % apply calibration to tr before converting
      combinetraces = true;
      
   end
   
   properties(Dependent)
      nrecs  % number or records for current database ptr
      dbfields % field names for current database ptr
      epochstart % start time(s) as epoch number
      epochend % end time(s) as  epoch number
   end
   
   methods
      % DATE get/set
      function val = get.epochstart(obj)
         val = antelopsource.mat2epoch(obj.matlabstart);
      end
      function val = get.epochend(obj)
         val = antelopesource.mat2epoch(obj.matlabend);
      end
      function obj = set.epochstart(obj, val)
         obj.matlabstart = antelopesource.epoch2mat(val);
      end
      function obj = set.epochend(obj, val)
         obj.matlabend = antelopesource.epoch2mat(val);
      end
      function obj = set.matlabstart(obj, val)
         if ischar(val) || iscell(val)
            val = datnum(val);
         end
         obj.matlabstart = val;
      end
      function obj = set.matlabend(obj, val)
         if ischar(val) || iscell(val)
            val = datnum(val);
         end
         obj.matlabend = val;
      end
         
      function data = retrieve(obj, where_, from_ , until_)
         assert(numel(datenum(from_)) == numel(datenum(until_)),...
            'Waveform:load_antelope:startEndMismatch', 'Unequal number of start and end times');
         % fill antelope source with proper search criteria
         obj.matlabstart = from_;
         obj.matlabend = until_;
         obj.chaninfo = where_;
         % database to open needs to be determined from all the above
         % do once for each date? each channel?
         obj = obj.open('r');
         % the following needs to be repeated for each where_
         obj = obj.subsetbyLocation(1);
         obj = obj.subsetbyTime(1);
         try
            w = obj.getAllTraces();
         catch
            w = obj.getTracesOneAtATime();
         end
         
                  
         % return if no rows
         if dbnrecs(obj.dbpointer)==0
            %no data returned
            return
         end
         fprintf('Got %d matching records\n',dbnrecs(db));
         [wfid,sta,chan,st,et]=dbgetv(db, 'wfid','sta','chan','time', 'endtime');
         sta = cellstr(sta);
         chan = cellstr(chan);
         for c=1:numel(sta)
            fprintf('%12d %s %s %f %f\n',wfid(c), sta{c}, chan{c}, st(c), et(c));
         end
         
         % if starttime and endtime blank, get from min/max times in wfdisc table
         if isempty(starttime) & isempty(endtime)
            starttime = min(st);
            endtime = max(et);
         end
      end
      
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
      
      function obj = subsetbyLocation(obj, n)
         searchstr = antelopesource.buildSearchCriterion(obj.chaninfo(n));
         obj.dbpointer = dbsubset(obj.dbpointer, searchstr);
      end
      function obj = subsetbyTime(obj, n)
         searchstr = sprintf('time <= %f && endtime >= %f',obj.epochend(n), obj.epochstart(n))
         obj.dbpointer = dbsubset(obj.dbpointer, searchstr);
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
      
      function sc = buildSearchCriterion(chaninfo)
         sc = addto('','sta',chaninfo.station);
         sc = addto(sc,'chan',chaninfo.channel);
         % the following aren't understood, and therefore aren't used
         %sc = addto(sc,'net',chaninfo.network);
         %sc = addto(sc,'loc',chaninfo.location);
      end
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
      
      function Ep = mat2epoch(M)
         %mat2epoch   convert matlab time to epoch time (millisecond precision)
         %   uses Antelope's conversion
         %
         %   if string is converted, then expected format is: 'yyyy-mm-dd HH:MM:SS.FFF'
         %
         %   See also str2epoch, datestr
         if isnumeric(M)
            M = datestr(M,'yyyy-mm-dd HH:MM:SS.FFF');
         end
         Ep = str2epoch(M);  
      end
      function M = epoch2mat(Ep)
         %epoch2mat   convert epoch time to matlab time (millisecond precision)
         %   Uses Antelope's conversion
         %
         %  See also epoch2str, datenum
         M = datenum(epoch2str(Ep,'%G %T'));
      end
      
      function trs = trsTrimStarts(trs, desiredStartEpoch)
         %trsTrimStarts   trims data and adjusts starttime of trStructs
         %   trs = trsTrimStarts(trs, desiredStartEpoch)
         %   adjusts the trs.time, trs.strtime, and trs.data fields
         %
         %   if desiredStartEpoch < trs.time, this does nothing.
         %
         %   See also tr2struct
         for n=1:numel(trs)
            actualStartEpoch = trs(n).time;
            secondsToTrim = desiredStartEpoch - actualStartEpoch;
            if secondsToTrim < 0, continue; end
            samplesToTrim = fix(secondsToTrim * trs(n).samplerate);
            secondsActuallyTrimmed =  samplesToTrim / trs(n).samplerate;
            trs(n).time = actualStartEpoch - secondsActuallyTrimmed;
            trs(n).data(1:samplesToTrim) = []; % remove leading samples
            startString = trs(n).strtime;
            startMat = datenum(startString);
            matSecondsTrimmed = datenum([0,0,0,0,0,secondsActuallyTrimmed]);
            trs(n).strtime = datestr(startMat - matSecondsTrimmed,...
               'mm/dd/yyyy HH:MM:SS.FFF'); %notice date format!
         end
         
      end
      
      function trStructs = safe_trload(db, st, et)
         %safe_trload   load a trace (get the struct) and expand time range on failure
         %  trStructs = safe_trload(db, startEpoch, endEpoch)
         %  assumes that db is already subset
         %  returned trace structure may have more data than expected
         earliestStart = min([db.start]);
         tr = [];
         while st >= min([db.start])
            try
               tr = trload_css(mydb, st, et);
            catch
               st = max(st - 60, earliestStart); % back up 60 seconds & try again
            end
         end
         if isempty(tr)
            error('Unable to acess data by merely backing up in time');
         end
         trsplice(tr, 20)
         trStructs = tr2struct(tr);
         trfree(tr);
         trStructs = antelopesource.trsTrimStarts(trStructs, st);
      end
      
      function T = trstruct2SeismicTrace(trs)
         %trstruct2SeismicTrace  convert all trstructs to SeismicTraces
         %  trstruct2SeismicTrace(trs) where trs is the result of tr2struct,
         %  performed on a tr pointer.
         T = SeismicTrace();
         T = repmat(T,size(trs));
         for n=1:numel(trs)
            T(n).start = trs(n).strtime;
            T(n).data = trs(n).data;
            T(n).station = trs(n).sta;
            T(n).channel = trs(n).chan;
            T(n).network = trs(n).net;
            T(n).samplerate = trs(n).samprate;
            T(n).units = segtype2units(trs(n).segtype);
            T(n).calib.applied = false;
            T(n).calib.value = trs(n).calib;
         end
      end
   end
   
   end

   %{
   example of a trStuct
   ans = 
          evid: -1
          arid: -1
           net: '-'
           sta: 'AKT'
          chan: 'HHZ'
          time: 1.3215e+09
       endtime: 1.3215e+09
     processid: -1
         nsamp: 93399
      samprate: 99.9985
       instype: '-'
         calib: 1.3962
        calper: -1
      response: 0
      datatype: 'sd'
       segtype: 'V'
      procflag: 0
          data: [93399x1 double]
           lat: -999
           lon: -999
          elev: -999
        refsta: '-'
        dnorth: 0
         deast: 0
        edepth: 0
          hang: 0
          vang: 0
       comment: 0
            m0: 0
            m1: 0
           mt0: -1.0000e+10
           mt1: -1.0000e+10
    bundletype: 0
         dbptr: [1x1 struct]
       strtime: '11/16/2011  16:27:50.006'
    strendtime: '11/16/2011  16:43:23.999'

   %}
