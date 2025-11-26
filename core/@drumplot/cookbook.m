%% drumplot Cookbook (GISMO)
% The drumplot class generates helicorder-style plots (multi-line seismic
% displays) from waveform objects. Optionally, detected events from a
% Catalog or Detection object can be superimposed.
%
% This cookbook is fully CI-safe:
%   • Uses synthetic waveform data by default
%   • Does NOT require SAC, Antelope, Winston, or IRIS
%   • Optional real-data sections are guarded
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
x(5000:5100)  = x(5000:5100)  + 10*gausswin(101);
x(25000:25200)= x(25000:25200)+ 8*gausswin(201);

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
%% 5. Add synthetic detections (CI-safe)
%% ------------------------------------------------------------------------

% Build a small fake Detection object if class exists
try
    trigTimes = start + [5 12 17]/1440;
    det = Detection();
    det.trig = trigTimes(:);
    det.dur  = 5*ones(size(trigTimes(:)));
    
    h2 = drumplot(w2,'mpl',5,'detections',det);

    figure('Name','Drumplot with detections');
    plot(h2)
catch
    disp('Detection class not available — skipping detection overlay demo.');
end

%% ------------------------------------------------------------------------
%% 6. Using plot_helicorder wrapper (waveform method)
%% ------------------------------------------------------------------------

try
    figure('Name','plot\_helicorder wrapper demo');
    plot_helicorder(w2,'mpl',5);
catch
    disp('plot_helicorder not available — skipping wrapper demo.');
end

%% ------------------------------------------------------------------------
%% OPTIONAL REAL-DATA EXAMPLE (SAC)
%% This is ONLY executed if GISMO TESTDATA exists
%% ------------------------------------------------------------------------

if exist('TESTDATA','var') || ~isempty(getenv('TESTDATA'))
    try
        testDataPath = getenv('TESTDATA');
        sacfile = fullfile(testDataPath,'waveform_data','REF.EHZ.2009-03-22.sac');

        if exist(sacfile,'file') == 2
            ds = datasource('sac',sacfile);
            ctag = ChannelTag('AV.REF..EHZ');

            snum = datenum(2009,3,22);
            enum = snum + 1;

            wreal = waveform(ds,ctag,snum,enum);
            wreal = fillgaps(wreal,'interp');
            wreal = detrend(wreal);
            wreal = filtfilt(fobj,wreal);

            wshort = extract(wreal,'time',snum,snum+1/24);

            hreal = drumplot(wshort,'mpl',5);

            figure('Name','Real SAC data drumplot');
            plot(hreal)
        end
    catch ME
        warning('Real-data drumplot example skipped: %s',ME.message);
    end
end

%% ------------------------------------------------------------------------
%% Notes
%% ------------------------------------------------------------------------
% This cookbook focuses on visualization and interaction. Automated
% correctness testing should reside in:
%
%   tests/test_drumplot.m   (to be created)
%
% This file is intended for:
%   • human learning
%   • GitHub tutorial rendering
%   • classroom teaching
%   • documentation publication