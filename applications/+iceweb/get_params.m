%% TYPICAL SETTINGS

% Waveform plot
products.waveform_plot.doit = true;

% RSAM settings
products.rsam.samplingIntervalSeconds = [60]; % [1 60] means record RSAM data at 1-second and 60-second intervals
products.rsam.measures = {'median'}; % {'max';'mean';'median'} records the max, mean and median in each 1-second and 60-second interval
products.rsam.doit = true;

% 10-minute spectrogram settings
%products.spectrograms.fmin = 0.5; % has no effect
products.spectrograms.fmax = 100; % Hz
products.spectrograms.dBmin = 60; % white level
products.spectrograms.dBmax = 120; % pink level
products.spectrograms.timeWindowMinutes = 10; % 10 minute spectrograms. 60 minute spectrograms is another common choice but incompatible with PhP code
products.spectrograms.doit = true; % plot spectrograms?
products.spectrograms.plot_metrics = false; % superimpose metrics on spectrogram plots

% Spectral data archiving
products.spectral_data.doit = true; % whether to compute & save spectral data
products.spectral_data.samplingIntervalSeconds = 60; % DO NOT CHANGE! spectral data are archived at this interval

% Sound files when clicking on 10-minute spectrogram panels?
products.soundfiles.doit = false;

% Reduced displacement settings
products.reduced.doit = false; % probably doesn't exist
products.reduced.samplingIntervalSeconds = 60;

% Cleaning up
products.removeWaveformFiles = false;

% Making summary daily plots
products.daily.spectrograms = true;
products.daily.helicorders = true;
products.daily.rsamplots = true;
products.daily.spectralplots = true;
products.daily.reduced = false;

%% products.level
% this is a master switch. if set to 'minimal', it will turn off compute
% RSAM and spectral data, but no figures will be produced
if isfield(products,'level') 
    if strcmp(products.level,'minimal')
        % Minimal level is aimed at computing RSAM and spectral data only
        % So we turn off 10-minute spectrograms and waveform plots and
        % remove waveform files but still make daily plots
        products.waveform_plot.doit = false;
        products.spectrograms.doit = false; 
        products.soundfiles.doit = false;
        products.removeWaveformFiles = true;
    elseif strcmp(products.level,'everything')
        % At everything level, we add 1-second RSAM, we also compute max
        % and mean RSAM, we superimpose metrics on spectrograms, add sound
        % files, and plot reduced displacement (not yet enabled)
        products.rsam.samplingIntervalSeconds = [1 60]; % add 1 second RSAM too
        products.rsam.measures = {'max';'mean';'median'}; % create more types of RSAM
        products.spectrograms.plot_metrics = true; % superimpose metrics on spectrograms
        products.soundfiles.doit = true;
        products.reduced.doit = true;   % though it probably does nothing     
        products.daily.reduced = true; % does nothing yet
    end
end

% data will be swallowed in chunks of this size
% 1 hour is optimal for speeding through data - smaller and larger chunks
% will take longer overall
% should always be at least products.spectrograms.timeWindowMinutes
% otherwise spectrograms will be incomplete
gulpMinutes = products.spectrograms.timeWindowMinutes;

% I think TZ is only used for the new version of utnow in iceweb2017 and
% that is only used for debug output, so this can be ignored
global TZ
TZ = 0;