function wavef = load_irisdmcws(request)
   
   % LOAD_IRISDMCWS loads waveforms using the IRIS Web Services Java Library
   % For more information about the IRIS Web Services Library for Java,
   % check out
   %
   % http://www.iris.edu/manuals/javawslibrary/
   %
   % See also javaaddpath waveform
   % request.combineWaves is ignored
   
   % Based on work by: Rich Karstens & Celso Reyes IRIS DMC, December 2011
   
   [~, allChanInfo, sTime, eTime, ~] = unpackDataRequest(request);
   disp('Requesting Data from the DMC...');
   
   datefmt = @(dt) datestr(dt, 'yyyy-mm-dd HH:MM:SS.FFF');
   idx = 0;
   for d = 1 : numel(sTime);
   for tag = allChanInfo
      thisWave = irisFetchTraces(...
         tag.network, tag.station, tag.location, tag.channel, datefmt(sTime(d)), datefmt(eTime(d)));
      nWaves = numel(thisWave);
      if nWaves > 0
         wavef(idx + 1 : idx + nWaves) = thisWave;
         idx = numel(wavef);
      end;
   end
   end
   wavef = addhistory(clearhistory(wavef),'Imported from IRIS DMC');
end

function ts = irisFetchTraces( network, station, location, channel, startDateStr, endDateStr, quality, verbosity )
   % irisFetchTraces
   %   Returns an array of Matlab trace structures (rather than Java classes)
   %   based on standard waveform criteria
   
   % % Load up that jar if necessary
   
   if ~exist('verbosity', 'var')
      verbosity = false;
   end
   
   if ~exist('quality', 'var')
      quality = 'B';
   end
   
   try
      % traces = edu.iris.WsHelper.Fetch.TraceData.fetchTraces(network, station, location, channel, startDateStr, endDateStr, quality, verbosity);
      fetcher = edu.iris.dmc.extensions.fetch.TraceData();
      appName           = ['MATLAB:waveformsuite/2.0']; %used as useragent of queries'
      fetcher.setAppName(appName);
      traces = fetcher.fetchTraces(network, station, location, channel, startDateStr, endDateStr, quality, false);
      ts = convertTraces(traces);
      clear traces;
   catch je
      switch je.identifier
         case 'MATLAB:undefinedVarOrClass'
            % The library was not found
            error('WAVEFORM:load_irisdmcws:unableToAccessLibrary',...
               ['The IRIS-WS library was not found in the matlab ',...
               'path.  Please ensure it is on your system, and ',...
               'has been added to MATLAB''s java path.  For more ',...
               'information about using MATLAB with the IRIS-WS ',...
               'library, visit:\n\n',...
               '\thttp://www.iris.edu/manuals/javawslibrary/matlab/\n']);
         case 'MATLAB:Java:GenericException'
            if isa(je.ExceptionObject,'edu.iris.dmc.service.NoDataFoundException')
               fprintf('no data found for:\n%s.%s.%s.%s %s %s\n',network, station,...
                  location, channel, startDateStr, endDateStr);
               ts = [];
            else
               rethrow(je);
            end
         otherwise
            disp(je.identifier)
            rethrow(je);
      end
   end
end


function ws = convertTraces(traces)
   for i = 1:length(traces)
      w = waveform;
      chaninfo = channeltag(char(traces(i).getNetwork), ...
         char(traces(i).getStation), ...
         char(traces(i).getLocation), ...
         char(traces(i).getChannel));
      w = set(w,'channelinfo',chaninfo,'freq',traces(i).getSampleRate); %, 'start', datenum(startDateStr, 'yyyy-mm-dd HH:MM:SS.FFF'));
      w = set(w,'start', char(traces(i).getStartTime.toString()));
      w = addfield(w,'latitude',traces(i).getLatitude);
      w = addfield(w,'longitude', traces(i).getLongitude);
      w = addfield(w,'elevation',traces(i).getElevation);
      w = addfield(w,'depth',traces(i).getDepth);
      w = addfield(w,'azimuth',traces(i).getAzimuth);
      w = addfield(w,'dip',traces(i).getDip);
      w = addfield(w,'sensitivity',traces(i).getSensitivity);
      w = addfield(w,'sensitivityFrequency',traces(i).getSensitivityFrequency);
      w = addfield(w,'instrument',char(traces(i).getInstrument));
      w = set(w,'units',char(traces(i).getSensitivityUnits));
      w = addfield(w,'calib',1 ./ traces(i).getSensitivity);
      w = addfield(w,'calib_applied','NO');
      w = set(w,'data', traces(i).getAsDouble()); % was traces(i).getData();
      ws(i) = w;
   end
end

