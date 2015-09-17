function w = load_from_datasource(ds, chans, startt, endt, COMBINE_WAVES, usewkaround)
   %load_from_datasource
   %
   % w = load_from_datasource(ds, chans, startt, endt, COMBINE_WAVES)
   
   % determine the load function based upon the datasource's type
   
   if isVoidInterpreter(ds)
      ds = setinterpreter(ds, get_load_routine(ds, usewkaround));
   end
   request = makeDataRequest(ds, chans, startt, endt);
   getter = get(ds,'interpreter');
   w = getter(request, COMBINE_WAVES);
   
   % TODO: Trim waveform to request
   % maybe we're already done?
   disp('done?')
   return
   % -------------------------------------------------------------------
   % if the datasource is file based, or if it requires a user-defined
   % intepreter function, then do what follows.  Otherwise, we're done
   
   if ~isVoidInterpreter(ds)
      myLoadFunc = get(ds,'interpreter');
      
      %user_defined datasource
      ALLOW_MULTIPLE = true;
      ERROR_ON_EMPTY = true;
      for j = 1:numel(startt)
         myStartTime = startt(j);
         myEndTime = endt(j);
         
         % grab all files for date range, discarding duplicates
         fn = getfilename(ds, chans,subdivide_files_by_date(ds,myStartTime, myEndTime));
         fn = unique(fn);
         
         %load all waveforms for these files
         clear somew
         
         for i=1:numel(fn)
            w = load_from_file(myLoadFunc,fn{i},ALLOW_MULTIPLE, ERROR_ON_EMPTY);
            %w = w(ismember([w.cha_tag],[chans])); %keep only appropriate station/chan
            ct = w.cha_tag;
            w = w(ct.matching(chans)); %Not 100% sure about this one
            w = filter_by_time(w, myStartTime, myEndTime);
            if numel(w) > 0
               somew(i) = {w};
            end
         end %for fn
         if ~exist('somew','var')
            w = waveform; w = w([]);
         else
            if COMBINE_WAVES,
               w = combine([somew{:}]);
            else
               w = [somew{:}];
            end
         end
         allw(j) = {w};
      end %each start time
      w = [allw{:}];
   end %~isVoidInterpreter
end

function tf = isVoidInterpreter(ds)
   tf = strcmpi(func2str(get(ds,'interpreter')),'void_interpreter');
end

function datarequest = makeDataRequest(ds, chans, st, ed)
   %makeDataRequest 
   % move to datasource?
   datarequest = struct(...
      'dataSource', ds, ...
      'scnls', chans, ...
      'startTimes', st,...
      'endTimes',ed);
end