function wavef = load_irisdmcws(dataRequest, combine_waves)

% LOAD_IRISDMCWS loads waveforms using the IRIS Web Services Java Library
% For more information about the IRIS Web Services Library for Java,
% check out  
%
% http://www.iris.edu/manuals/javawslibrary/  
%
% 

% Rich Karstens & Celso Reyes
% IRIS DMC, December 2011

[myDataSource, allSCNLs, sTime, eTime] = unpackDataRequest(dataRequest);
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
        thisEndIndex = n + offset + numel(thisWaveform) - 1
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
        traces = edu.iris.WsHelper.Fetch.TraceData.fetchTraces(network, station, location, channel, startDateStr, endDateStr, quality, verbosity);
        ts = convertTraces(traces);
        clear traces;
    catch je
        fprintf('Exception occured in IRIS Web Services Library: %s\n', je.message);
    end
end


function ws = convertTraces(traces)
   for i = 1:length(traces)
       w = waveform;
       myscnl = scnlobject(char(traces(i).station), ...
           char(traces(i).channel), ...
           char(traces(i).network), ...
           char(traces(i).location));
       w = set(w,'scnlobject',myscnl,'freq',traces(i).sampleRate); %, 'start', datenum(startDateStr, 'yyyy-mm-dd HH:MM:SS.FFF'));
       w = set(w,'start', char(traces(i).startTime.toString()));
       w = addfield(w,'latitude',traces(i).latitude);
       w = addfield(w,'longitude', traces(i).longitude);
       w = addfield(w,'elevation',traces(i).elevation);
       w = addfield(w,'depth',traces(i).depth);
       w = addfield(w,'azimuth',traces(i).azimuth);
       w = addfield(w,'dip',traces(i).dip);
       w = addfield(w,'sensitivity',traces(i).sensitivity);
       w = addfield(w,'sensitivityFrequency',traces(i).sensitivityFrequency);
       w = addfield(w,'instrument',char(traces(i).instrument));
       w = set(w,'units',char(traces(i).sensitivityUnits));
       w = addfield(w,'calib',traces(i).sensitivity);
       w = addfield(w,'calib_applied','NO');
       w = set(w,'data', traces(i).data);
       ws(i) = w;
   end
end

