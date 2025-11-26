%% waveform Cookbook (GISMO)
% The waveform object is the GISMO data type for holding seismic waveform
% data. The basic idea is that in GISMO we do not care whether waveform data
% come from MiniSEED, SAC, SEISAN, Earthworm, Winston, Antelope, or IRIS.
% Everything is handled through a unified waveform object.

%% ------------------------------------------------------------------------
% Class location
%   core/@waveform/
%
% This cookbook is for:
%   • Human learning
%   • Manual exploration
%   • Classroom demonstrations
%
% Automated validation is handled exclusively by:
%   tests/test_waveform_core.m
%   tests/test_waveform_datasources.m
%% ------------------------------------------------------------------------

close all

%% ------------------------------------------------------------------------
%% Reading local data files (MiniSEED, SAC, SEISAN)
%% ------------------------------------------------------------------------

if exist('TESTDATA','var') || ~isempty(getenv('TESTDATA'))

    TESTDATA = getenv('TESTDATA');

    %% MiniSEED
    fprintf('\n--- MiniSEED example ---\n');
    filepath = fullfile(TESTDATA, 'waveform_data', 'REF.EHZ.2009.081');
    if exist(filepath,'file')
        w = waveform(filepath, 'seed');
        plot(w)
        title('MiniSEED waveform')
    else
        disp('MiniSEED example file not found. Skipping...');
    end

    %% SAC
    fprintf('\n--- SAC example ---\n');
    filepath = fullfile(TESTDATA, 'waveform_data', 'REF.EHZ.2009-03-22.sac');
    if exist(filepath,'file')
        w = waveform(filepath, 'sac');
        plot(w)
        title('SAC waveform')
    else
        disp('SAC example file not found. Skipping...');
    end

    %% SEISAN
    fprintf('\n--- SEISAN example ---\n');
    filepath = fullfile(TESTDATA, 'waveform_data', '2001-02-02-0303-55S.MVO___019');
    if exist(filepath,'file')
        w = waveform(filepath, 'seisan');
        plot(w)
        title('SEISAN waveform')
    else
        disp('SEISAN example file not found. Skipping...');
    end

else
    disp('TESTDATA not defined — skipping local file examples.');
end

%% ------------------------------------------------------------------------
%% Reading waveform data from IRIS DMC Web Services
%% ------------------------------------------------------------------------

if exist('irisFetch','file') == 2
    fprintf('\n--- IRIS DMC Web Services example ---\n');

    ds = datasource('irisdmcws');
    ctag = ChannelTag('AV', 'RSO', '--', 'EHZ');

    startTime = '2009/03/22 06:00:00';
    endTime   = '2009/03/22 07:00:00';

    try
        w = waveform(ds, ctag, startTime, endTime);
        plot(w)
        title('IRIS DMC waveform')
    catch ME
        warning('IRIS retrieval failed: %s', ME.message);
    end
else
    disp('irisFetch not found — skipping IRIS DMC example.');
end

%% ------------------------------------------------------------------------
%% Reading waveform data from Winston server
%% ------------------------------------------------------------------------

fprintf('\n--- Winston example ---\n');
try
    ds = datasource('winston', 'pubavo1.wr.usgs.gov', 16022);
    ctag = ChannelTag('AV', 'RSO', '--', 'EHZ');

    startTime = now - 1/24;
    endTime   = now;

    w = waveform(ds, ctag, startTime, endTime);
    plot(w)
    title('Winston waveform')

catch
    disp('Winston server unavailable — skipping Winston example.');
end

%% ------------------------------------------------------------------------
%% Reading waveform data from Antelope CSS3.0 databases
%% ------------------------------------------------------------------------

if admin.antelope_exists()
    fprintf('\n--- Antelope CSS3.0 example ---\n');

    if exist('TESTDATA','var') || ~isempty(getenv('TESTDATA'))
        dbpath = fullfile(getenv('TESTDATA'), 'css3.0', 'demodb');
    else
        disp('No TESTDATA path available for Antelope example.');
        dbpath = '';
    end

    if exist(dbpath,'dir')
        ds = datasource('antelope', dbpath);
        ctag = ChannelTag('AV', 'REF', '--', 'EHZ');

        startTime = '2009/03/23 06:00:00';
        endTime   = '2009/03/23 07:00:00';

        w = waveform(ds, ctag, startTime, endTime);
        plot(w)
        title('Antelope waveform')
    else
        disp('Antelope demo database not found — skipping.');
    end
else
    disp('Antelope not installed — skipping CSS3.0 examples.');
end

%% ------------------------------------------------------------------------
%% Basic waveform processing
%% ------------------------------------------------------------------------

if exist('w','var') && ~isempty(w)

    fprintf('\n--- Basic waveform processing ---\n');

    %% Fill gaps (interpolate NaNs)
    w1 = fillgaps(w, 'interp');

    %% Detrend
    w2 = detrend(w1);

    %% High-pass filter
    f = filterobject('h', 0.5, 2);
    w3 = filtfilt(f, w2);

    figure('Name','Processing chain');
    subplot(3,1,1), plot(w),  title('Raw waveform')
    subplot(3,1,2), plot(w2), title('Detrended')
    subplot(3,1,3), plot(w3), title('Filtered')

end

%% ------------------------------------------------------------------------
%% Spectral analysis
%% ------------------------------------------------------------------------

if exist('w','var') && ~isempty(w)

    fprintf('\n--- Spectral analysis ---\n');
    s = amplitude_spectrum(w);
    figure
    plot(s.f, s.amp);
    xlabel('Frequency (Hz)');
    ylabel('Amplitude');
    title('Amplitude spectrum')

end

%% ------------------------------------------------------------------------
%% Spectrogram
%% ------------------------------------------------------------------------

if exist('w','var') && ~isempty(w)
    fprintf('\n--- Spectrogram ---\n');
    spectrogram(w);
end

%% ------------------------------------------------------------------------
%% Helicorder (drum) plot
%% ------------------------------------------------------------------------

if exist('w','var') && ~isempty(w)
    fprintf('\n--- Helicorder plot ---\n');
    plot_helicorder(w);
end

%% ------------------------------------------------------------------------
%% Notes
% Additional waveform methods are documented at:
% https://github.com/geoscience-community-codes/GISMO/tree/master/core/@waveform
%
% Automated verification of waveform behavior is performed by:
%   tests/test_waveform_core.m
%   tests/test_waveform_datasources.m
%% ------------------------------------------------------------------------