%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULTS - MAXIMAL - DO NOT RECOMMEND CHANGING THESE
defaultSamplingIntervalSeconds = 60;
products.waveform_plot.doit = true;
products.rsam.doit = true;
products.rsam.samplingIntervalSeconds = [1 defaultSamplingIntervalSeconds]; % [1 60] means record RSAM data at 1-second and 60-second intervals
products.rsam.measures = {'max';'mean';'median'}; % {'max';'mean';'median'} records the max, mean and median in each 1-second and 60-second interval
products.spectrograms.doit = true; % whether to plot & save spectrograms
products.spectrograms.plot_metrics = true; % superimpose metrics on spectrograms
products.spectrograms.timeWindowMinutes = 60; % 60 minute spectrograms. 10 minute spectrograms is another common choice
%products.spectrograms.fmin = 0.5;
products.spectrograms.fmax = 100; % Hz
products.spectrograms.dBmin = 60; % white level
products.spectrograms.dBmax = 120; % pink level
products.spectral_data.doit = true; % whether to compute & save spectral data
products.spectral_data.samplingIntervalSeconds = defaultSamplingIntervalSeconds; % DO NOT CHANGE! spectral data are archived at this interval
products.soundfiles.doit = true;
products.helicorders.doit = true;
products.reduced.doit = false;
products.reduced.samplingIntervalSeconds = defaultSamplingIntervalSeconds;
products.removeWaveformFiles = false;

% daily plots
products.daily.spectrograms = true;
products.daily.helicorders = true;
products.daily.rsamplots = true;
products.daily.spectralplots = true;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% products.minimal
% this is a master switch. if true, it will turn off plotting of all figures less
% than 1 day. spectrograms will be computed, but no figures saved.
% if true, iceweb behaves as if spectrograms.doit, soundfiles.doit, 
% helicorders.doit and reduced.doit are all false, and daily.spectrograms,
% daily.rsamplots, daily.helicorders and daily.spectralplots are true.
if isfield(products,'minimal') & products.minimal
    products.daily.spectrograms = true;
    products.daily.helicorders = false;
    products.daily.rsamplots = true;
    products.daily.spectralplots = false;
    products.waveform_plot.doit = false;
    products.rsam.samplingIntervalSeconds = [60];
    products.rsam.measures = {'mean'};
    products.spectrograms.doit = false; % whether to plot & save spectrograms
    products.spectrograms.plot_metrics = false; % superimpose metrics on spectrograms
    products.spectral_data.doit = true; % whether to compute & save spectral data
    products.soundfiles.doit = false;
    products.helicorders.doit = false;
    products.reduced.doit = false;
    products.removeWaveformFiles = true;
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