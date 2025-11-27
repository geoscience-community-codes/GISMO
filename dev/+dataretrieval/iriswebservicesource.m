classdef iriswebservicesource < dataretrieval.spatiotemporal_database
   %UNTITLED2 Summary of this class goes here
   %   Detailed explanation goes here
   
   properties
   end
   
   methods
      function waves = retrieve(obj, where_, from_ , until_)
         disp('Requesting Data from the DMC...');
         offset = 0;
         for n = 1 : numel(where_)
            chanTag = where_(n);
            
            thisTrace = dataretrieval.iriswebservicesource.getTraces(chanTag, ...
               datestr(from_,'yyyy-mm-dd HH:MM:SS.FFF'), ...
               datestr(until_,'yyyy-mm-dd HH:MM:SS.FFF'));
            
            if numel(thisTrace) == 1
               waves(n+ offset) = thisTrace;
            elseif numel(thisTrace) > 1
               thisEndIndex = n + offset + numel(thisTrace) - 1;
               waves(n+offset : thisEndIndex) = thisTrace;
               offset = offset + numel(thisTrace) - 1;
            end
         end
      end
   end
   methods (Static, Access=protected)
      function ts = getTraces( chanInfo, fromStr, untilStr, quality, verbosity )
         % getTraces returns an array of Matlab trace structures based on standard waveform criteria
         
         % % Load up that jar if necessary
         
         if ~exist('verbosity', 'var')
            verbosity = false;
         end
         
         if ~exist('quality', 'var')
            quality = 'B';
         end
         
         try
            tdclass = edu.iris.dmc.extensions.fetch.TraceData;
            % traces = edu.iris.WsHelper.Fetch.TraceData.fetchTraces(network, station, location, channel, startDateStr, endDateStr, quality, verbosity);
            traces = tdclass.fetchTraces(...
               chanInfo.network, chanInfo.station, chanInfo.location, chanInfo.channel,...
               fromStr, untilStr, quality, verbosity);
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
         ts = dataretrieval.iriswebservicesource.translate(traces);
         clear traces
         clear td
      end
      
      function ws = translate(traces)
         for i = 1:length(traces)
            w = waveform;
            chaninfo = ChannelTag(char(traces(i).getNetwork), ...
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
            w = set(w,'data', traces(i).getAsDouble()); % might need more flexability here
            ws(i) = w;
         end
      end
      
   end
   
end
