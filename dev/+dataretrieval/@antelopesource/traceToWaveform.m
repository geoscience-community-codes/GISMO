function allw = traceToWaveform(obj)
   %traceToWaveform converts traceobjects to waveforms
   %    w = traceToWaveform(antelopesource)
   %
   % Note: this may return multiple waveform objects, depending upon
   % how many segments and/or scnl's.
   
   wBlank = antelopesource.blankWaveformWithCalib();
   
   try
      traceCount = dbnrecs(obj.trpointer);
      assert(traceCount > 0);
   catch er
      disp('traceToWaveform: No traces found to convert');
      allw = wBlank([]);
      return
   end
   
   % preallocations
   spikes(traceCount).mask = false; %used to track data spikes & inf values
   allw = repmat(wBlank,traceCount,1);
   
   % LOOP twice through segments represented by this trace object
   % 1st loop: find signal spikes, and get header info.
   for seg = 1:traceCount
      obj.trpointer.record = seg - 1;
      allw(seg) = waveformMetadata(wBlank, obj.trpointer);
      spikes(seg).mask = findSpikes(obj.trpointer);
   end
   
   allw = applyCalibrationsToAll(trpointer, allw);
   
   % 2nd loop: assign data to the waveforms.
   replaceWithNan = @(W,BAD) setsamples(W, BAD.mask, nan);
   for seg = 1:traceCount
      obj.trpointer.record = seg - 1;
      allw(seg) = set(allw(seg), 'data', trextract_data(obj.trpointer));
      allw(seg) = replaceWithNan(allw(seg), spikes(seg));
   end
end


function w = waveformMetadata(w, trpointer)
   s = db2struct(trpointer); %do once, get one for each segment
   [sunit, ~] = segtype2units(s.segtype);
   w = set(w, ...
      'station', s.sta, ...
      'channel', s.chan, ...
      'network', s.net, ...
      ...'location', s.loc, ... % unknown if 'loc' really is a field
      'start', datenum(epoch2str(s.time,'%Y-%m-%d %H:%M:%S.%s')), ...
      'freq', s.samprate, ...
      'units', sunit, ...
      'calib', s.calib);
end

function spikes = findSpikes(trpointer)
      % data spikes must be known PRIOR to applying calibration
      maxAllowableSignal = (realmax('single') * 1e-2);
      data = trextract_data(trpointer);
      spikes = (abs(data) >= maxAllowableSignal) | isinf(data);
end

function allw = applyCalibrationsToAll(trpointer, allw)
   % now, apply calibrations to all traces at once
   trapply_calib(trpointer);
   hasCalibs = get(allw,'calib') ~= 0;
   allw(hasCalibs) = set(allw(hasCalibs),'calibration_applied','YES');
end