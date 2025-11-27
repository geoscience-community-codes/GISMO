%% GISMO Training 01: Waveforms, RSAM, and Basic Processing
%
% This script is a training / teaching example, not a unit test.
% It demonstrates:
%   • Reading waveform data from common file formats
%   • Basic waveform methods and plotting
%   • RSAM generation and saving
%   • Simple STA/LTA detection
%   • Cleaning “messy” waveforms
%
% It assumes your GISMO test data are under a directory pointed to by the
% GISMO_DATA environment variable, e.g.
%   export GISMO_DATA=/path/to/GISMO_DATA
%
% Paths below use:
%   <GISMO_DATA>/testdata/miniseed/...
%   <GISMO_DATA>/testdata/sac/...
%   <GISMO_DATA>/testdata/seisan/...

clc;
close all;
warning off; %#ok<WNOFF>

%% --- Resolve GISMO_DATA root -------------------------------------------
gismoData = getenv('GISMO_DATA');
if isempty(gismoData)
    error(['GISMO_DATA environment variable is not set. ' ...
           'Set it to the root of your GISMO test data folder.']);
end

%% 1. INTRODUCTION
% See the GitHub wiki for background material:
%   • What is GISMO?
%   • Who uses it?
%   • Historical development
%   • Object-oriented programming in GISMO

% https://github.com/geoscience-community-codes/GISMO/wiki

%% 2. WAVEFORM DATA

%% 2.1 Reading waveform data
% To retrieve a waveform object, the command is:
%    w = waveform(ds, scnl, starttime, endtime)
%
% Arguments:
%   ds        - datasource object (where to get the data from)
%   scnl      - scnlobject (station, channel, network, location)
%   starttime - MATLAB datenum
%   endtime   - MATLAB datenum

%% (a) MiniSEED example: single station, one day
mseedFile = fullfile(gismoData, 'testdata', 'miniseed', 'REF.EHZ.2009.080');
ds   = datasource('miniseed', mseedFile);
scnl = scnlobject('REF', 'EHZ');
t1   = datenum(2009,3,21);
t2   = datenum(2009,3,22);

w1 = waveform(ds, scnl, t1, t2)

%% (b) SAC example: single station, one day
sacFile = fullfile(gismoData, 'testdata', 'sac', 'REF.EHZ.2009-03-22.sac');
ds   = datasource('sac', sacFile);
scnl = scnlobject('REF', 'EHZ');
t1   = datenum(2009,3,22);
t2   = datenum(2009,3,23);

w2 = waveform(ds, scnl, t1, t2)

%% (c) SEISAN example: multiple stations
seisanFile = fullfile(gismoData, 'testdata', 'seisan', 'WAV', 'MVOE_', ...
                      '2001', '02', '2001-02-02-0303-55S.MVO___019');
ds   = datasource('seisan', seisanFile);
scnl = scnlobject('*', 'BHZ');
t1   = datenum(2001,2,2,3,3,0);
t2   = datenum(2001,2,2,3,23,0);

w3 = waveform(ds, scnl, t1, t2)

% w3 is an array of waveform objects (one per station/channel).

%% 2.2 Waveform methods
% For a full list of methods associated with waveform objects:
methods(waveform)

% Get help on a specific method:
help waveform/combine

% We can combine w1 and w2 because they are the same station & channel and
% consecutive days, even though they came from different file types.
w4 = combine([w1 w2])

%% 2.3 Plotting waveform data

% (a) Simple plot of a single waveform
figure;
plot(w4);
title('REF EHZ – combined MiniSEED + SAC');

% (b) Change x-axis units to hours
figure;
plot(w4, 'xunit', 'hours');
title('REF EHZ – time axis in hours');

% (c) Helicorder-style plot
figure;
plot_helicorder(w4, 'mpl', 60);  % 60 minutes per line

% (d) Plotting multiple stations (from SEISAN)
figure;
plot(w3);
title('Multiple stations (raw plot)');

% (e) Use plot_panels for a cleaner multi-trace display
figure;
plot_panels(w3, true);

% (f) Amplitude spectra for a subset of stations
figure;
plot_spectrum(w3([8 11 18]));

% (g) Spectrograms
figure;
spectrogram(w3([8 11 18]));

%% 2.4 Processing waveform data

% Extract a 1-hour subset from w4
w5 = extract(w4, 'time', ...
    datenum(2009,3,22,20,0,0), ...
    datenum(2009,3,22,21,0,0))

% Plot raw subset
figure;
plot(w5);
title('Raw 1-hour subset (REF EHZ)');

% Plot displacement, velocity, acceleration
figure;

ax(1) = subplot(3,1,1);
fobj  = filterobject('h', 0.5, 2);   % high-pass 0.5 Hz
w5f   = filtfilt(fobj, w5);
plot(integrate(w5f));
ylabel('Displacement'); grid on;

ax(2) = subplot(3,1,2);
plot(w5f);
ylabel('Velocity'); grid on;

ax(3) = subplot(3,1,3);
plot(diff(w5f));
ylabel('Acceleration'); grid on;

linkaxes(ax, 'x');

%% 2.5 Save waveform as audio
% This can be fun in training courses.
waveform2sound(w5f, 60, 'REF_EHZ_example.wav');

%% 3. RSAM DATA

%% 3.1 Reading RSAM data from a BOB file
% For training, we assume a demo RSAM file under GISMO_DATA/testdata/rsam.
rsamFile = fullfile(gismoData, 'testdata', 'rsam', 'MOMN2015.DAT');

s = rsam.read_bob_file('file', rsamFile, ...
    'snum', datenum(2015,1,1), ...
    'enum', datenum(2015,2,1), ...
    'sta',  'MOMN', ...
    'units','Counts')

%% 3.2 Plotting RSAM data
figure;
s.plot();
title('RSAM example (MOMN 2015)');

%% 3.3 Generating RSAM from waveform data
r = waveform2rsam(w4);
figure;
r.plot();
title('RSAM computed from REF EHZ waveforms');

%% 3.4 Saving RSAM data

% (a) Save to a text file
r.toTextFile('REF_EHZ_2009_RSAM.txt');
type('REF_EHZ_2009_RSAM.txt');

% (b) Save to a binary (BOB) file
r.save('YYYY_SSSS_CCC_MMMM.bob');

%% 4. STA/LTA EVENT DETECTION (simple example)

% Define STA/LTA parameters
sta_seconds  = 0.7;
lta_seconds  = 7.0;
thresh_on    = 3.0;
thresh_off   = 1.5;
min_dur      = 2.0;   % minimum event duration (s)

event_detection_params = [sta_seconds lta_seconds thresh_on thresh_off ...
                          min_dur];

% Run the STA/LTA detector (LTA “frozen” when triggered)
[cobj, sta, lta, sta_to_lta] = Detection.sta_lta( ...
    w5f, ...
    'edp', event_detection_params, ...
    'lta_mode', 'frozen');

% Plot detected events on top of helicorder
figure;
plot_helicorder(w5f, 'mpl', 5, 'catalog', cobj);
title('STA/LTA detections on helicorder');

%% 5. SAC POLE–ZERO FILES AND RESPONSES (if available)

pzFile = fullfile(gismoData, 'testdata', 'sacpz', ...
                  'SACPZ.IU.COLA.10.BHZ');

if exist(pzFile, 'file')
    pz = sacpz(pzFile);
    figure;
    pz.plot();
    title('SAC PZ response (IU COLA BHZ)');

    f = 0.1:0.1:10.0;
    r = pz.to_response_structure(f);

    figure;
    loglog(r.frequencies, abs(r.values));
    xlabel('Frequency (Hz)');
    ylabel('|Response|');
    grid on;
    title('Amplitude response from SAC PZ');
else
    warning('SAC PZ demo file not found: %s', pzFile);
end

%% 6. CLEANING WAVEFORM DATA (TRAINING DEMO)

% Seismic data can have problems:
%   • spikes (outliers)
%   • dropouts (NaNs)
%   • drift / trends
%   • band-limited noise

% Start from w5f and deliberately “mess it up”
w6 = messitup_for_training(w5f);

figure;
ax = gobjects(6,1);

ax(1) = subplot(3,2,1); plot(w5f); title('raw'); grid on;
ax(2) = subplot(3,2,2); plot(w6);  title('messed up'); grid on;

% (a) Despike with median filter
w6a = medfilt1(w6, 3);
ax(3) = subplot(3,2,3); plot(w6a); title('despiked'); grid on;

% (b) Fill gaps (NaNs) by interpolation
w6b = fillgaps(w6a, 'interp');
ax(4) = subplot(3,2,4); plot(w6b); title('interpolated'); grid on;

% (c) Detrend
w6c = detrend(w6b);
ax(5) = subplot(3,2,5); plot(w6c); title('detrended'); grid on;

% (d) Band-pass filter 0.5–15 Hz
fobj = filterobject('b', [0.5 15], 2);
w6d  = filtfilt(fobj, w6c);
ax(6) = subplot(3,2,6); plot(w6d); title('filtered'); grid on;

linkaxes(ax, 'x');

figure;
ax(1) = subplot(2,1,1); plot(w5f); title('original clean'); grid on;
ax(2) = subplot(2,1,2); plot(w6d); title('recovered after cleaning'); grid on;
linkaxes(ax, 'x');

%% END OF TRAINING SCRIPT
disp('GISMO Training 01 complete.');

%% ------------------------------------------------------------------------
function wMessy = messitup_for_training(w)
%MESSITUP_FOR_TRAINING Deliberately corrupt a waveform for cleaning demos.
%
%   wMessy = messitup_for_training(w)
%
% Adds:
%   • high-frequency noise
%   • slow trend
%   • random spikes

t = get(w,'timevector');
x = get(w,'data');

% Normalize
m = max(abs(x));
if m == 0
    wMessy = w;
    return;
end
x = x / m;

% (1) Add high-frequency noise (0.6 of Nyquist)
fs = 1 / (t(2)-t(1));
x  = x + sin(2*pi*0.3*fs*t) / 10;

% (2) Add slow linear trend
x = x + (t - t(1)) / (t(end) - t(1)) * 10;

% (3) Add random spikes
c = 3;
while c < numel(x)
    r = rand;
    if r < 0.001
        x(c) = x(c) + abs(3*randn);  % spike
        c = c + 100;
    end
    c = c + 1;
end

wMessy = set(w, 'data', x * m);
end