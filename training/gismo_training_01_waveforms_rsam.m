%% GISMO Training 01: Waveforms, RSAM, and Basic Processing
%
% Training / teaching script (not a unit test).
%
% Demonstrates:
%   • Reading waveform data from common file formats
%   • Basic waveform methods and plotting
%   • RSAM generation and saving
%   • Simple STA/LTA detection
%   • Cleaning “messy” waveforms
%
% REQUIREMENTS:
%   • GISMO startup completed (startup_GISMO)
%   • TESTDATA installed via admin.download_testdata
%
% This script is CI-safe and deterministic.

clc;
close all;
warning off; %#ok<WNOFF>

disp('--- GISMO Training 01: Waveforms & RSAM ---');

%% ------------------------------------------------------------------------
%% Resolve TESTDATA (authoritative)
%% ------------------------------------------------------------------------
if ~admin.is_testdata_setup(false)
    error(['TESTDATA not configured.\n' ...
           'Run admin.download_testdata or run_all_training first.']);
end

global TESTDATA
testdataRoot = TESTDATA;

fprintf('Using TESTDATA at:\n  %s\n', testdataRoot);

%% ------------------------------------------------------------------------
%% 1. WAVEFORM DATA
%% ------------------------------------------------------------------------

%% 1.1 MiniSEED: single station, one day
mseedFile = fullfile(testdataRoot,'miniseed','REF.EHZ.2009.080');

ds   = datasource('miniseed', mseedFile);
scnl = scnlobject('REF','EHZ');
t1   = datenum(2009,3,21);
t2   = datenum(2009,3,22);

w1 = waveform(ds, scnl, t1, t2);
disp(w1);

%% 1.2 SAC: same station, next day
sacFile = fullfile(testdataRoot,'sac','REF.EHZ.2009-03-22.sac');

ds   = datasource('sac', sacFile);
scnl = scnlobject('REF','EHZ');
t1   = datenum(2009,3,22);
t2   = datenum(2009,3,23);

w2 = waveform(ds, scnl, t1, t2);
disp(w2);

%% 1.3 Combine consecutive days
w4 = combine([w1 w2]);

%% ------------------------------------------------------------------------
%% 2. Plotting
%% ------------------------------------------------------------------------

figure;
plot(w4);
title('REF EHZ – combined MiniSEED + SAC');

figure;
plot(w4,'xunit','hours');
title('REF EHZ – time axis in hours');

figure;
plot_helicorder(w4,'mpl',60);

%% ------------------------------------------------------------------------
%% 3. SEISAN: multi-station example
%% ------------------------------------------------------------------------

seisanFile = fullfile(testdataRoot,'seisan','WAV','MVOE_', ...
                      '2001','02','2001-02-02-0303-55S.MVO___019');

ds   = datasource('seisan', seisanFile);
scnl = scnlobject('*','BHZ');

t1 = datenum(2001,2,2,3,3,0);
t2 = datenum(2001,2,2,3,23,0);

w3 = waveform(ds, scnl, t1, t2);

figure;
plot_panels(w3,true);
title('SEISAN multi-station waveforms');

%% ------------------------------------------------------------------------
%% 4. Processing example
%% ------------------------------------------------------------------------

w5 = extract(w4,'time', ...
    datenum(2009,3,22,20,0,0), ...
    datenum(2009,3,22,21,0,0));

figure;
plot(w5);
title('Raw 1-hour subset');

fobj = filterobject('h',0.5,2);
w5f  = filtfilt(fobj,w5);

figure;
subplot(3,1,1); plot(integrate(w5f)); ylabel('Displacement'); grid on
subplot(3,1,2); plot(w5f);            ylabel('Velocity');     grid on
subplot(3,1,3); plot(diff(w5f));      ylabel('Acceleration'); grid on

%% ------------------------------------------------------------------------
%% 5. RSAM
%% ------------------------------------------------------------------------

rsamFile = fullfile(testdataRoot,'rsam','MOMN2015.DAT');

s = rsam.read_bob_file( ...
    'file', rsamFile, ...
    'snum', datenum(2015,1,1), ...
    'enum', datenum(2015,2,1), ...
    'sta',  'MOMN', ...
    'units','Counts');

figure;
s.plot();
title('RSAM from BOB file');

r = waveform2rsam(w4);
figure;
r.plot();
title('RSAM computed from waveform');

%% ------------------------------------------------------------------------
%% 6. STA/LTA detection
%% ------------------------------------------------------------------------

edp = [0.7 7.0 3.0 1.5 2.0];

[cobj,~,~,~] = Detection.sta_lta( ...
    w5f, ...
    'edp', edp, ...
    'lta_mode','frozen');

figure;
plot_helicorder(w5f,'mpl',5,'catalog',cobj);
title('STA/LTA detections');

%% ------------------------------------------------------------------------
%% 7. SAC Pole–Zero (optional, if file exists)
%% ------------------------------------------------------------------------

pzFile = fullfile(testdataRoot,'sacpz','SACPZ.IU.COLA.10.BHZ');

if exist(pzFile,'file')
    pz = sacpz(pzFile);

    figure;
    pz.plot();
    title('SAC Pole–Zero response');

    f = 0.1:0.1:10;
    R = pz.to_response_structure(f);

    figure;
    loglog(R.frequencies,abs(R.values));
    grid on
    xlabel('Frequency (Hz)');
    ylabel('|Response|');
end

%% ------------------------------------------------------------------------
%% 8. Cleaning demo
%% ------------------------------------------------------------------------

wMessy = messitup_for_training(w5f);

wClean = filtfilt( ...
    filterobject('b',[0.5 15],2), ...
    detrend(fillgaps(medfilt1(wMessy,3),'interp')) );

figure;
subplot(2,1,1); plot(w5f);   title('Original clean');
subplot(2,1,2); plot(wClean);title('Recovered after cleaning');

disp('GISMO Training 01 complete.');

%% ======================================================================
function wMessy = messitup_for_training(w)
t = get(w,'timevector');
x = get(w,'data');
m = max(abs(x));
if m == 0, wMessy = w; return; end

x = x/m;
fs = 1/(t(2)-t(1));

x = x + sin(2*pi*0.3*fs*t)/10;               % HF noise
x = x + (t-t(1))/(t(end)-t(1))*10;           % trend

for k = 1:100:numel(x)
    if rand < 0.2
        x(k) = x(k) + abs(3*randn);
    end
end

wMessy = set(w,'data',x*m);
end