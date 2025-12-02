function cookbook()
%% RSAM Class Cookbook (Core GISMO)
%
% End-to-end demonstration and validation of the RSAM workflow:
%
%   1. Load waveform data (TESTDATA if available, otherwise synthetic)
%   2. Compute RSAM with different measures and window lengths
%   3. Plot RSAM objects (single + panels)
%   4. Save RSAM to text and BOB files
%   5. Reload RSAM from legacy Montserrat BOB files (optional)
%
% This cookbook is:
%   ✓ CI-safe
%   ✓ Free of Antelope/IceWeb dependencies
%   ✓ Fully reproducible with or without TESTDATA
%
% Glenn Thompson / Refactored 2025

close all
clc

fprintf('\n=== RSAM COOKBOOK START ===\n');

%% ------------------------------------------------------------------------
%% 1. Load a Waveform Object
%% ------------------------------------------------------------------------
fprintf('\n--- Loading waveform for RSAM ---\n');

useTestData = false;

try
    admin.is_testdata_setup(false);
    global TESTDATA

    mseedFile = fullfile(TESTDATA, ...
        'miniseed_data','REF.EHZ.2009.081');

    if exist(mseedFile,'file') == 2
        useTestData = true;
    end
catch
end

if useTestData
    fprintf('Using TESTDATA waveform: %s\n', mseedFile);

    ds   = datasource('miniseed', mseedFile);
    snum = datenum(2009,3,22,0,0,0);
    enum = snum + 1/24;   % 1 hour
    ctag = ChannelTag('', 'REF', '', 'EHZ');

    w = waveform(ds, ctag, snum, enum);

else
    fprintf('TESTDATA not available — using synthetic waveform.\n');

    fs = 20;                       % 20 Hz
    t  = (0:1/fs:3600)';           % 1 hour
    data = 1000 * sin(2*pi*2*t);   % tremor-like 2 Hz signal
    data = data + 200 * randn(size(data));

    w = waveform('XX.TEST..BHZ', fs, fix(now), data, 'Counts');
end

figure('Name','RSAM Input Waveform','Color','w');
plot(w);
title('Input Waveform for RSAM');

%% ------------------------------------------------------------------------
%% 2. Compute RSAM with Different Measures
%% ------------------------------------------------------------------------
fprintf('\n--- Computing RSAM ---\n');

% Default: mean, 60 s
rsam_mean_60 = waveform2rsam(w);

% Explicit equivalent
rsam_mean_60b = waveform2rsam(w, 'mean', 60);

% Max amplitude, 10 s (event-sensitive)
rsam_max_10 = waveform2rsam(w, 'max', 10);

% Median amplitude, 600 s (tremor-sensitive)
rsam_med_600 = waveform2rsam(w, 'median', 600);

rsam_vec = [rsam_mean_60 rsam_max_10 rsam_med_600];

fprintf('Computed RSAM objects:\n');
disp(rsam_vec);

%% ------------------------------------------------------------------------
%% 3. Plot RSAM Objects
%% ------------------------------------------------------------------------
fprintf('\n--- Plotting RSAM ---\n');

figure('Name','RSAM Time Series','Color','w');
rsam_vec.plot();
legend('Mean 60 s','Max 10 s','Median 600 s');
title('RSAM Time Series');

figure('Name','RSAM Panel Plot','Color','w');
rsam_vec.plot_panels();
title('RSAM Panel Plot');

%% ------------------------------------------------------------------------
%% 4. Save RSAM to Text Files
%% ------------------------------------------------------------------------
fprintf('\n--- Saving RSAM to text files ---\n');

tmpdir = fullfile(tempdir, 'gismo_rsam_cookbook');
if ~exist(tmpdir,'dir')
    mkdir(tmpdir);
end

txtfile = fullfile(tmpdir,'REF.EHZ.10s.max.txt');
rsam_max_10.save_to_text_file(txtfile);

if exist(txtfile,'file') ~= 2
    error('RSAM cookbook failed to write text file.');
end

fprintf('Saved RSAM text file: %s\n', txtfile);

%% ------------------------------------------------------------------------
%% 5. Save RSAM to BOB Files
%% ------------------------------------------------------------------------
fprintf('\n--- Saving RSAM to BOB files ---\n');

bobfile = fullfile(tmpdir, 'REF.EHZ.10s.max.bob');
rsam_max_10.save_to_bob_file(bobfile);

if exist(bobfile,'file') ~= 2
    error('RSAM cookbook failed to write BOB file.');
end

fprintf('Saved RSAM BOB file: %s\n', bobfile);

% File-pattern bulk saving
patternFile = fullfile(tmpdir,'SSSS.CCC.YYYY.MMMM.bob');
rsam_vec.save_to_bob_file(patternFile);

fprintf('Saved bulk-pattern BOB files: %s\n', patternFile);

%% ------------------------------------------------------------------------
%% 6. Load Legacy RSAM from Montserrat BOB Files (Optional)
%% ------------------------------------------------------------------------
fprintf('\n--- Attempting legacy Montserrat RSAM load ---\n');

if useTestData
    dp = fullfile(TESTDATA,'rsam','MCPZ1996.DAT');

    if exist(dp,'file') == 2
        fprintf('Loading legacy RSAM BOB file: %s\n', dp);

        s = rsam.read_bob_file(dp, ...
            'snum', datenum(1996,12,1), ...
            'enum', datenum(1996,12,31), ...
            'sta', 'MCPZ', ...
            'units', 'Counts');

        figure('Name','Legacy Montserrat RSAM','Color','w');
        s.plot();
        title('Legacy RSAM Loaded from MCPZ1996.DAT');

        fprintf('Loaded legacy RSAM: %d samples\n', numel(s.data));
    else
        fprintf('Legacy BOB file missing — skipping legacy load.\n');
    end
else
    fprintf('TESTDATA not available — skipping legacy BOB loading.\n');
end

%% ------------------------------------------------------------------------
%% 7. RSAM Object Inspection
%% ------------------------------------------------------------------------
fprintf('\n--- Inspecting RSAM object ---\n');

disp(rsam_mean_60);
disp('RSAM properties:');
disp(get(rsam_mean_60));

fprintf('RSAM sampling interval: %.1f s\n', ...
    get(rsam_mean_60,'sampling_interval'));
fprintf('RSAM measure: %s\n', ...
    get(rsam_mean_60,'measure'));

%% ------------------------------------------------------------------------
%% Final Status
%% ------------------------------------------------------------------------
fprintf('\n=== RSAM COOKBOOK COMPLETED SUCCESSFULLY ===\n');

end
