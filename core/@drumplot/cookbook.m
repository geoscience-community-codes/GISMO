function cookbook()
%% drumplot Cookbook (GISMO)
% The drumplot class generates helicorder-style plots (multi-line seismic
% displays) from waveform objects. Optionally, detected events from a
% Catalog or Detection object can be superimposed.
%
% This cookbook is fully CI-safe:
%   • Uses synthetic waveform data by default
%   • Does NOT require SAC, Antelope, Winston, or IRIS
%   • Optional real-data sections are guarded by TESTDATA
%
% See also:
%   drumplot, waveform, plot_helicorder, Detection, Catalog

close all

%% ------------------------------------------------------------------------
%% 1. Create a synthetic 1-hour waveform
%% ------------------------------------------------------------------------

fs = 100;                % 100 Hz sample rate
T  = 3600;               % 1 hour (seconds)
t  = (0:1/fs:T-1/fs)';   % time vector

% Synthetic seismic-like signal
x = 0.1 * randn(size(t));                    % background noise
x = x + sin(2*pi*2*t);                       % 2 Hz tremor
x(5000:5100)   = x(5000:5100)   + 10*gausswin(101);
x(25000:25200) = x(25000:25200) +  8*gausswin(201);

ctag  = ChannelTag('XX.SYN..BHZ');
start = fix(now);

w = waveform(ctag, fs, start, x, 'Counts');

figure('Name','Synthetic waveform');
plot(w)

%% ------------------------------------------------------------------------
%% 2. Preprocessing
%% ------------------------------------------------------------------------

w = fillgaps(w,'interp');
w = detrend(w);

fobj = filterobject('b',[0.5 15],2);
w = filtfilt(fobj,w);

figure('Name','Filtered waveform');
plot(w)

%% ------------------------------------------------------------------------
%% 3. Extract first 20 minutes
%% ------------------------------------------------------------------------

w2 = extract(w,'time',start,start+20/1440);

%% ------------------------------------------------------------------------
%% 4. Basic helicorder plot
%% ------------------------------------------------------------------------

h = drumplot(w2,'mpl',5);

figure('Name','Basic drumplot');
plot(h)

%% ------------------------------------------------------------------------
%% 5. Add synthetic detections (CI-safe, Detection API-consistent)
%% ------------------------------------------------------------------------

% Build a small fake Detection object if the class exists
try
    trigTimes = start + [5 12 17]/1440;   % three "events" in minutes

    det = Detection();
    % Use Detection API fields that are actually used by associate()
    det.time  = trigTimes(:);
    det.state = repmat({'D'}, numel(trigTimes), 1);  % "D" for "detection"

    h2 = drumplot(w2,'mpl',5,'detections',det);

    figure('Name','Drumplot with synthetic detections');
    plot(h2)
catch ME
    disp(['Detection class not available or incompatible — ' ...
          'skipping synthetic detection overlay demo. (' ME.message ')']);
end

%% ------------------------------------------------------------------------
%% 6. Using plot_helicorder wrapper (waveform method)
%% ------------------------------------------------------------------------

try
    figure('Name','plot_helicorder wrapper demo');
    plot_helicorder(w2,'mpl',5);
catch ME
    disp(['plot_helicorder not available — skipping wrapper demo. (' ...
          ME.message ')']);
end

%% ------------------------------------------------------------------------
%% 7. OPTIONAL REAL-DATA EXAMPLE (MiniSEED)
%% This is ONLY executed if TESTDATA is configured
%%   TESTDATA/miniseed_data/REF.EHZ.2009.081
%% ------------------------------------------------------------------------

testdata = getenv('TESTDATA');
if ~isempty(testdata)
    try
        mseedfile = fullfile(testdata,'miniseed_data','REF.EHZ.2009.081');

        if exist(mseedfile,'file') == 2
            ds   = datasource('miniseed', mseedfile);
            ctag = ChannelTag('XX.REF..EHZ');  % generic network

            wreal = waveform(ds, ctag);
            wreal = fillgaps(wreal,'interp');
            wreal = detrend(wreal);
            wreal = filtfilt(fobj,wreal);

            [snum, enum] = gettimerange(wreal);
            wshort = extract(wreal,'time',snum,min(snum+1/24,enum));

            hreal = drumplot(wshort,'mpl',5);

            figure('Name','Real MiniSEED data drumplot');
            plot(hreal)
        else
            disp('MiniSEED file REF.EHZ.2009.081 not found in TESTDATA/miniseed_data — skipping real-data demo.');
        end
    catch ME
        warning('Real-data drumplot example skipped: %s',ME.message);
    end
else
    disp('TESTDATA not defined — skipping real-data MiniSEED drumplot example.');
end

%% ------------------------------------------------------------------------
%% Notes
%% ------------------------------------------------------------------------
% This cookbook focuses on visualization and interaction. Automated
% correctness testing should reside in:
%
%   tests/test_drumplot.m
%
% This file is intended for:
%   • human learning
%   • GitHub tutorial rendering
%   • classroom teaching
%   • documentation publication
end
