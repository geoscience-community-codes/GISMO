%% GISMO Training 05: Volcano Monitoring Workflow
%
% This training demonstrates a complete observatory-style workflow:
%
%   1. Continuous waveform ingestion
%   2. Tremor vs VT signal separation
%   3. STA/LTA event detection
%   4. Catalog creation
%   5. RSAM computation
%   6. EventRate tracking
%   7. Drumplot visualization with events
%
% The script is CI-safe and automatically uses:
%   • Local MiniSEED if present
%   • Otherwise IRIS DMC (if internet is available)
%
%% NOTE:
% This training prefers local MiniSEED.
% If local data are absent, it optionally falls back to IRIS and therefore
% requires:
%   • MATLAB R2022b or earlier
%   • irisFetch + IRIS Java libraries
%   • Active internet connection
% The script will automatically skip if these are unavailable.
%
% ------------------------------------------------------------

clc;
close all;
warning off; %#ok<WNOFF>

disp('--- GISMO Training 05: Volcano Monitoring Workflow ---');

%% 1. Data Source Selection (Local → IRIS Fallback) ----------------------

useIRIS = false;

if exist('training_05_local.mseed','file')
    disp('Using local MiniSEED file...');
    ds = datasource('miniseed','training_05_local.mseed');
    scnl = scnlobject('REF','EHZ');
    startTime = datenum(2009,3,23,6,0,0);
    endTime   = datenum(2009,3,23,7,0,0);
else
    disp('Local data not found. Testing IRIS availability...');

    % --- MATLAB version guard
    v = ver('MATLAB');
    rel = regexp(v.Release,'\d{4}[ab]','match','once');
    if str2double(rel(1:4)) >= 2023
        warning('Training 05 skipped: irisFetch incompatible with MATLAB R2023a+');
        return
    end

    % --- Java IRIS library guard
    if exist('edu.iris.dmc.extensions.fetch.TraceData','class') ~= 8
        warning('Training 05 skipped: IRIS Java library not on classpath');
        return
    end

    % --- irisFetch availability
    if exist('irisFetch','file') ~= 2
        warning('Training 05 skipped: irisFetch not on path');
        return
    end

    % --- Internet / IRIS service guard
    try
        irisFetch.Networks('limit',1);
        useIRIS = true;
    catch
        warning('Training 05 skipped: IRIS not reachable');
        return
    end
end

if useIRIS
    disp('Using IRIS DMC...');
    ds = datasource('irisdmcws');
    scnl = scnlobject('REF','EHZ','AV','--');
    startTime = datenum(2009,3,23,6,0,0);
    endTime   = datenum(2009,3,23,7,0,0);
end

%% 2. Load Continuous Waveform ------------------------------------------

w = waveform(ds, scnl, startTime, endTime);
w = detrend(w);
w = fillgaps(w,'interp');

fprintf('Loaded %.1f minutes of continuous data\n', ...
    1440*get(w,'duration'));

%% 3. Basic Drumplot -----------------------------------------------------

figure;
plot_helicorder(w,'mpl',5);
title('Continuous Drumplot');

%% 4. Signal Band Separation (Tremor vs VT) ------------------------------

% Tremor band: 1–5 Hz
ftrem = filterobject('b',[1 5],2);
wtremor = filtfilt(ftrem,w);

% VT band: 0.5–15 Hz
fvt = filterobject('b',[0.5 15],2);
wvt = filtfilt(fvt,w);

figure;
subplot(3,1,1); plot(w);       title('Raw');
subplot(3,1,2); plot(wtremor); title('Tremor Band (1–5 Hz)');
subplot(3,1,3); plot(wvt);     title('VT Band (0.5–15 Hz)');

%% 5. STA/LTA Detection on VT Band --------------------------------------

sta = 0.7;     % seconds
lta = 7.0;     % seconds
on  = 3.0;
off = 1.5;
minDur = 2.0;

edp = [sta lta on off minDur];

[cobj,~,~,~] = Detection.sta_lta(wvt, ...
    'edp', edp, ...
    'lta_mode','frozen');

fprintf('Detected %d VT events\n', cobj.numberOfEvents);

%% 6. Plot Drumplot with Detected Events --------------------------------

figure;
plot_helicorder(w,'mpl',5,'catalog',cobj);
title('Drumplot with STA/LTA Detections');

%% 7. Compute RSAM for Tremor and VT ------------------------------------

rsam_tremor = waveform2rsam(wtremor,'mean',10);
rsam_vt     = waveform2rsam(wvt,'max',10);

figure;
subplot(2,1,1);
rsam_tremor.plot(); title('Tremor RSAM (10 s mean)');
subplot(2,1,2);
rsam_vt.plot();     title('VT RSAM (10 s max)');

%% 8. Build Event Catalog from Detections -------------------------------

% Convert detections to Catalog
evTimes = cobj.otime;

cat = Catalog( ...
    'otime',  evTimes, ...
    'lat',    zeros(size(evTimes)), ...
    'lon',    zeros(size(evTimes)), ...
    'depth',  zeros(size(evTimes)), ...
    'mag',    ones(size(evTimes)) );

fprintf('Catalog built with %d events\n', cat.numberOfEvents);

%% 9. Compute EventRate -------------------------------------------------

er = cat.eventrate('binsize',1/24);  % hourly

figure;
er.plot();
title('Hourly Event Rate');

%% 10. Compare RSAM and EventRate ---------------------------------------

figure;
subplot(2,1,1); rsam_vt.plot(); title('VT RSAM');
subplot(2,1,2); er.plot();      title('Event Rate');

%% 11. Save Monitoring Products ----------------------------------------

save('training_05_waveform.mat','w','wtremor','wvt');
save('training_05_rsam.mat','rsam_tremor','rsam_vt');
save('training_05_catalog.mat','cat');
save('training_05_eventrate.mat','er');

fprintf('Saved monitoring products to disk\n');

%% 12. Student Exercises -----------------------------------------------
%
%   • Compare tremor vs VT RSAM ratios
%   • Change STA/LTA thresholds and observe false alarms
%   • Compare daily vs hourly EventRate
%   • Implement energy-based RSAM
%   • Add infrasound channel comparison
%
% ------------------------------------------------------------

disp('GISMO Training 05 complete.');