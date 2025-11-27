%% GISMO Training 04: IRIS Event Search & Waveform Retrieval
%
% This training script demonstrates how to:
%
%   1. Search the IRIS database for earthquakes
%   2. Build a GISMO Catalog from IRIS events
%   3. Select nearby stations
%   4. Download waveform data for each event
%   5. Plot waveforms and spectrograms
%
% This script is safe for:
%   • GitHub
%   • Continuous Integration (CI)
%
% If IRIS is unreachable, the script automatically skips execution.
%
% ------------------------------------------------------------

clc;
close all;
warning off; %#ok<WNOFF>

disp('--- GISMO Training 04: IRIS Events & Waveforms ---');

%% 1. Test IRIS Availability --------------------------------------------

try
    irisFetch.Networks('limit',1);
    irisAvailable = true;
catch
    irisAvailable = false;
end

if ~irisAvailable
    warning('IRIS web services unavailable. Training 04 skipped.');
    return
end

%% 2. Define Search Region & Time ---------------------------------------

% Example: Walker Lane / Nevada region
minlat = 36.0;
maxlat = 41.0;
minlon = -121.0;
maxlon = -114.0;

minmag = 3.0;

starttime = '2016-12-01 00:00:00';
endtime   = '2016-12-31 23:59:59';

fprintf('Searching IRIS events: %s to %s\n', starttime, endtime);

%% 3. Retrieve Event Catalog from IRIS ----------------------------------

cobj = Catalog.retrieve('iris', ...
    'boxcoordinates', [minlat maxlat minlon maxlon], ...
    'starttime', starttime, ...
    'endtime',   endtime, ...
    'minimummagnitude', minmag);

fprintf('Retrieved %d events from IRIS\n', cobj.numberOfEvents);

%% 4. Basic Catalog Visualization ---------------------------------------

figure;
cobj.plot();
title('IRIS Event Map');

figure;
cobj.plot_time();
title('IRIS Event Time Series');

%% 5. Select Stations Near First Event ----------------------------------

eqlat = cobj.lat(1);
eqlon = cobj.lon(1);

searchRadiusDeg = km2deg(200);  % 200 km search radius

stations = irisFetch.Channels( ...
    'channel','*','*','*','BHZ', ...
    'radialcoordinates', [eqlat eqlon searchRadiusDeg 0], ...
    'StartTime', starttime, ...
    'EndTime',   endtime);

fprintf('Found %d nearby BHZ stations\n', numel(stations));

%% 6. Build ChannelTag Array --------------------------------------------

nscl = ChannelTag.array( ...
    {stations.NetworkCode}, ...
    {stations.StationCode}, ...
    {stations.LocationCode}, ...
    {stations.ChannelCode});

%% 7. Download Waveforms for First Event --------------------------------

pretrigger  = 60;   % seconds
posttrigger = 180;  % seconds

ds = datasource('irisdmcws');

eventTime = cobj.otime(1);

fprintf('Downloading waveforms for event at %s\n', datestr(eventTime));

for k = 1:numel(nscl)
    try
        w(k) = waveform(ds, ...
            nscl(k), ...
            eventTime - pretrigger/86400, ...
            eventTime + posttrigger/86400);
    catch
        w(k) = waveform();
    end
end

w = w(~isempty(w));

fprintf('Downloaded %d waveform traces\n', numel(w));

%% 8. Plot Event Waveforms ----------------------------------------------

figure;
plot_panels(w,true);
sgtitle('IRIS Event Waveforms');

%% 9. Spectrogram Visualization -----------------------------------------

figure;
spectrogram(w(1:min(6,end)));
sgtitle('Event Spectrograms');

%% 10. Compute RSAM for Event Window ------------------------------------

r = waveform2rsam(w,'mean',10);

figure;
r.plot();
title('Event RSAM (10 s)');

%% 11. Save for Downstream Work -----------------------------------------

save('training_04_iris_event_catalog.mat','cobj');
save('training_04_iris_event_waveforms.mat','w','r');

fprintf('Saved IRIS catalog and waveforms to disk\n');

%% 12. Student Exercises -----------------------------------------------
%
%   • Change region & magnitude threshold
%   • Compare shallow vs deep events
%   • Compute event spectra manually
%   • Estimate magnitudes from waveforms
%   • Compare RSAM vs EventRate
%
% ------------------------------------------------------------

disp('GISMO Training 04 complete.');