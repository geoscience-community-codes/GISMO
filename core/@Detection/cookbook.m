function cookbook()
%% Detection Cookbook (Core GISMO)
%
% This cookbook demonstrates the modern GISMO Detection workflow:
%
%   1. Load waveform data (TESTDATA or synthetic fallback)
%   2. Run STA/LTA detection
%   3. Inspect ON/OFF detection states
%   4. Associate detections into a Catalog
%   5. Visualize STA/LTA ratio and detections
%
% This cookbook is:
%   • CI-safe
%   • Antelope-free
%   • TESTDATA-optional
%
% Glenn Thompson / Refactored 2025

close all

disp('=== Detection Cookbook ===');

%% ------------------------------------------------------------------------
%% 1. Load Waveform (TESTDATA preferred, synthetic fallback)
%% ------------------------------------------------------------------------

useTestData = false;

try
    if admin.is_testdata_setup(false)
        global TESTDATA
        mseedFile = fullfile(TESTDATA, ...
            'miniseed_data','REF.EHZ.2009.081');

        if exist(mseedFile,'file') == 2
            w = waveform('miniseed', mseedFile);
            useTestData = true;
            disp('Using TESTDATA Redoubt MiniSEED example.');
        end
    end
catch
    useTestData = false;
end

if ~useTestData
    disp('TESTDATA not available — using synthetic waveform.');

    fs = 50;
    t  = (0:1/fs:3600)';
    tremor = 200 * sin(2*pi*2*t);
    noise  = 50 * randn(size(t));
    data   = tremor + noise;

    w = waveform('XX.TEST..BHZ', fs, fix(now), data, 'Counts');
end

figure('Visible','off');
plot(w);
title('Input Waveform');

%% ------------------------------------------------------------------------
%% 2. Run STA/LTA Detector
%% ------------------------------------------------------------------------

[det, sta, lta, ratio] = Detection.sta_lta(w);

disp(det);

%% ------------------------------------------------------------------------
%% 3. Sanity Checks on Output
%% ------------------------------------------------------------------------

assert(isa(det,'Detection'), 'STA/LTA did not return Detection object.');
assert(numel(sta)   == numel(get(w,'data')));
assert(numel(lta)   == numel(get(w,'data')));
assert(numel(ratio) == numel(get(w,'data')));

if det.numel > 0
    assert(mod(det.numel,2)==0, 'Detections must be ON/OFF paired.');
end

%% ------------------------------------------------------------------------
%% 4. Plot STA/LTA Ratio with Detections
%% ------------------------------------------------------------------------

figure('Visible','off');
tvec = get(w,'timevector');

plot(tvec, ratio,'k');
hold on; grid on;
ylabel('STA/LTA Ratio');
xlabel('Time');

if det.numel > 0
    yL = ylim;
    for k = 1:2:det.numel
        patch( ...
            [det.time(k) det.time(k+1) det.time(k+1) det.time(k)], ...
            [yL(1) yL(1) yL(2) yL(2)], ...
            [1 0.8 0.8], ...
            'FaceAlpha',0.3,'EdgeColor','none');
    end
end

title('STA/LTA Ratio with Detection Windows');

%% ------------------------------------------------------------------------
%% 5. Associate Detections into a Catalog
%% ------------------------------------------------------------------------

cat = det.associate(30);   % 30-second association window

disp(cat);

assert(isa(cat,'Catalog'), 'Association did not return a Catalog object.');

%% ------------------------------------------------------------------------
%% 6. Plot Resulting Catalog (if any)
%% ------------------------------------------------------------------------

if numel(cat.otime) > 0
    figure('Visible','off');
    stem(cat.otime, cat.mag, 'filled');
    datetick('x');
    xlabel('Time'); ylabel('Magnitude');
    title('Detection-Derived Event Catalog');
end

%% ------------------------------------------------------------------------
%% Summary
%% ------------------------------------------------------------------------

fprintf('\nDetection cookbook completed successfully.\n');

end
