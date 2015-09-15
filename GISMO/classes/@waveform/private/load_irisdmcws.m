function wavef = load_irisdmcws(dataRequest, combine_waves)
   
   % LOAD_IRISDMCWS loads waveforms using the IRIS Web Services Java Library
   % For more information about the IRIS Web Services Library for Java,
   % check out
   %
   % http://www.iris.edu/manuals/javawslibrary/
   %
   % See also javaaddpath waveform
   
   % Rich Karstens & Celso Reyes
   % IRIS DMC, December 2011
   
   [~, allSCNLs, sTime, eTime] = unpackDataRequest(dataRequest);
   disp('Requesting Data from the DMC...');
   offset = 0;
   for n=1:numel(allSCNLs)
      scnl = allSCNLs(n);
      thisWaveform=irisFetchTraces(get(scnl,'network'), get(scnl,'station'), ...
         get(scnl,'location'), get(scnl,'channel'), ...
         datestr(sTime,'yyyy-mm-dd HH:MM:SS.FFF'), ...
         datestr(eTime,'yyyy-mm-dd HH:MM:SS.FFF'));
      if numel(thisWaveform) == 1
         wavef(n+ offset) = thisWaveform;
      elseif numel(thisWaveform) > 1
         thisEndIndex = n + offset + numel(thisWaveform) - 1;
         wavef(n+offset : thisEndIndex) = thisWaveform;
         offset = offset + numel(thisWaveform) - 1;
      end
   end
   
   wavef = addhistory(clearhistory(wavef),'Imported from IRIS');
end

function [dataSource, scnls, startTimes, endTimes] = unpackDataRequest(dataRequest)
   dataSource = dataRequest.dataSource;
   scnls = dataRequest.scnls;
   startTimes = dataRequest.startTimes;
   endTimes = dataRequest.endTimes;
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
      traces = edu.iris.dmc.ws.extensions.fetch.TraceData.fetchTraces(network, station, location, channel, startDateStr, endDateStr, quality, verbosity);
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
         otherwise
            rethrow(je);
      end
   end
end


function ws = convertTraces(traces)
   for i = 1:length(traces)
      w = waveform;
      chaninfo = locationobject(char(traces(i).getNetwork), ...
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
      w = set(w,'data', traces(i).getData);
      ws(i) = w;
   end
end

