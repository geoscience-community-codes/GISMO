function cookbook()
%% RSAM Class Cookbook (Core GISMO)
% This tutorial demonstrates how to:
%   1. Compute RSAM from waveform objects
%   2. Plot RSAM objects
%   3. Save RSAM to text and BOB files
%   4. Load RSAM from legacy BOB files
%
% This cookbook is:
%   - CI-safe
%   - Free of Antelope/IceWeb dependencies
%   - Based only on synthetic data and GISMO TESTDATA
%
% Glenn Thompson / Refactored 2025

close all

%% ------------------------------------------------------------------------
%% 1. RSAM Concept Summary
%
% RSAM (Real-time Seismic Amplitude Measurement) is a time series derived
% from continuous seismic data by computing a statistic (e.g. mean absolute
% value, max, RMS, median) over fixed non-overlapping time windows.
%
% Core RSAM properties:
%   - dnum   : MATLAB datenums for each RSAM sample
%   - data   : RSAM values
%   - units  : Physical or digitizer units
%   - measure: Statistic used (mean, max, median, rms)
%   - ChannelTag
%   - sampling_interval (seconds)
%   - snum / enum (start and end time)

%% ------------------------------------------------------------------------
%% 2. Load a Waveform Object (synthetic or TESTDATA)
%
% Prefer TESTDATA if available; otherwise fall back to synthetic waveform.

if is_testdata_setup()
    fprintf('Using TESTDATA waveform example.\n');

    filepath = fullfile(TESTDATA, 'waveform_data', 'REF.EHZ.2009.081');
    ds = datasource('miniseed', filepath);

    snum = datenum(2009,3,22,0,0,0);
    enum = snum + 1/24;   % 1 hour
    ctag = ChannelTag('', 'REF', '', 'EHZ');

    w = waveform(ds, ctag, snum, enum);
else
    fprintf('TESTDATA not available — using synthetic waveform.\n');

    fs = 20;                       % 20 Hz
    t  = (0:1/fs:3600)';           % 1 hour
    data = 1000 * sin(2*pi*2*t);   % 2 Hz synthetic tremor
    data = data + 200 * randn(size(data));

    w = waveform('XX.TEST..BHZ', fs, fix(now), data, 'Counts');
end

figure; plot(w); title('Input Waveform');

%% ------------------------------------------------------------------------
%% 3. Compute RSAM with Different Measures

% Default: mean, 60 s
rsam_mean_60 = waveform2rsam(w);

% Explicit equivalent
rsam_mean_60b = waveform2rsam(w, 'mean', 60);

% Max amplitude, 10 s (event-sensitive)
rsam_max_10 = waveform2rsam(w, 'max', 10);

% Median amplitude, 600 s (tremor-sensitive)
rsam_med_600 = waveform2rsam(w, 'median', 600);

rsam_vec = [rsam_mean_60 rsam_max_10 rsam_med_600];

%% ------------------------------------------------------------------------
%% 4. Plot RSAM Objects

figure;
rsam_vec.plot();
legend('Mean 60 s','Max 10 s','Median 600 s');
title('RSAM Time Series');

figure;
rsam_vec.plot_panels();
title('RSAM Panel Plot');

%% ------------------------------------------------------------------------
%% 5. Save RSAM to Text Files

tmpdir = fullfile(tempdir, 'gismo_rsam_cookbook');
if ~exist(tmpdir,'dir'); mkdir(tmpdir); end

txtfile = fullfile(tmpdir,'REF.EHZ.10s.max.txt');
rsam_max_10.save_to_text_file(txtfile);

fprintf('Saved RSAM text file: %s\n', txtfile);

%% ------------------------------------------------------------------------
%% 6. Save RSAM to BOB Files

bobfile = fullfile(tmpdir, 'REF.EHZ.10s.max.bob');
rsam_max_10.save_to_bob_file(bobfile);

fprintf('Saved RSAM BOB file: %s\n', bobfile);

% File-pattern saving
rsam_vec.save_to_bob_file(fullfile(tmpdir,'SSSS.CCC.YYYY.MMMM.bob'));

%% ------------------------------------------------------------------------
%% 7. Load RSAM from Legacy BOB Files (if available)

if is_testdata_setup()

    dp = fullfile(TESTDATA,'rsam','MCPZ1996.DAT');

    fprintf('Loading legacy RSAM BOB file from TESTDATA.\n');

    s = rsam.read_bob_file(dp, ...
        'snum', datenum(1996,12,1), ...
        'enum', datenum(1996,12,31), ...
        'sta', 'MCPZ', ...
        'units', 'Counts');

    figure;
    s.plot();
    title('Legacy RSAM Loaded from BOB File');

else
    fprintf('Skipping legacy BOB load: TESTDATA not available.\n');
end

%% ------------------------------------------------------------------------
%% 8. RSAM Object Inspection

disp(rsam_mean_60);
disp('RSAM properties:');
disp(get(rsam_mean_60));

fprintf('RSAM sampling interval: %.1f s\n', get(rsam_mean_60,'sampling_interval'));
fprintf('RSAM measure: %s\n', get(rsam_mean_60,'measure'));

%% ------------------------------------------------------------------------
%% End of RSAM Cookbook
fprintf('\nRSAM core cookbook completed successfully.\n');

end