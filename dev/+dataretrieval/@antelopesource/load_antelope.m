function outputWaveforms = load_antelope(obj, specificDatabase)
   % load a waveform from antelope
   %  w = obj.load_antelope(specificDatabase)
   %   database is the antelope database
   
   % AUTHOR: Celso Reyes
   % MODIFICATIONS: Glenn Thompson, Carl Tape
   
   %TODO: maybe order of operations can be changed to avoid unpacking
   %request when unnecessary.
         
   %call this routine for each database, then return the waveforms.
   if exist('specificDatabase','var')
      obj.dbname = specificDatabase;
      outputWaveforms = emptyWaveform();
      
      %convert each channeltag into 
      obj = obj.buildSearchCriteria();
      for i = 1:numel(obj.searchcriteria)
         %if multiple traces will result, then there may be multiple records for tr
         [tr, dbname, fdb] = get_antelope_traces(obj, obj.searchcriteria{i});
         w = cycleThroughTraces(tr, obj.combinetraces);
         outputWaveforms = [outputWaveforms; w]; %#ok<AGROW>
      end
      dbclose(fdb);
   else
      outputWaveforms = RecursivelyLoadFromEachDatabase(obj);
   end
end
