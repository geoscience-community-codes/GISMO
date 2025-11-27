function [obj, rawDb, filteredDb] =  get_antelope_traces(obj)
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
   
   useExistingDatabasePtr =  obj.pointsToAntelopeDatabase;
   
   if useExistingDatabasePtr
      try
         dbnrecs(obj.dbpointer);
      catch
         warning('Waveform:load_antelope:databaseNotOpen', ...
            'a Database Pointer was passed to trace, but the database was not open');
         %tr = trnew; %return a new object, forcing the ability to destroy it later
         obj.trpointer = { -1 };
         return;
      end
   end
   
   % do not close the database if a pointer is asked for in the return arguments
   onFinishCloseDB = nargout < 2;
   
   antelope_starts = mep2dep(obj.startdate);
   antelope_ends = mep2dep(obj.enddates);
   
   if ~obj.isopen()
      obj = obj.open();
   end
   
   %if the database isn't already open, then open it for reading
   if ~obj.pointsToAntelopeDatabase
      obj = obj.open();
   else
      mydb = obj.dbpointer;
   end
   %check to ensure wfdisk table exists and is populated
   
   if obj.nrecs == 0,
      cleanUpFail('Waveform:load_antelope:databaseNotFound', ...
         'Database not found: %s', dbquery(mydb,'dbTABLE_FILENAME'));
      return;
   end;
   
   rawDb = mydb;   % keep a copy of the pre-subset (raw) database
   
   % subset the data based upon the desired criteria
   %criteriaList = keepCriteriaThatMatchDatabaseFields(criteriaList, mydb);
   %allExp = getAsExpressions(criteriaList);
   
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
         trStructs = safe_trload(db, st, et);
         T = trstruct2SeismicTrace(trStructs);
         try
            obj.trpointer{mytimeIDX} = trload_css(mydb, antelope_starts(mytimeIDX), antelope_ends(mytimeIDX)); %#ok<AGROW>
         catch
            cleanUpFail('Waveform:load_antelope:trload_css failed', ...
               'Database not found: %s', dbquery(mydb,'dbTABLE_FILENAME'));
            disp(obj.dbname)
            disp(allExp)
            starttimes = antelope_starts(mytimeIDX);
            endtimes = antelope_ends(mytimeIDX);
            fprintf('%.0f %.0f\n ',starttimes,endtimes);
            disp(['starttimes: ', datestr(epoch2datenum(starttimes))]);
            disp(['endtimes: ', datestr(epoch2datenum(endtimes))]);
            fprintf('trload_css(mydb, starttimes, endtimes))\n');
            return
         end
         trsplice(obj.trpointer{mytimeIDX},20);
      else
         obj.trpointer{mytimeIDX} = -1; %#ok<AGROW>
      end
   end %mytimeIDX
   closeIfAppropriate(mydb, onFinishCloseDB);
   
   function cleanUpFail(varargin)
      %cleanUpFail   tidy up database and records and display warning
      closeIfAppropriate(mydb, onFinishCloseDB);
      obj.trpointer = { -1 };
      filteredDb = dbinvalid;
      warning(varargin{:});      
   end
end