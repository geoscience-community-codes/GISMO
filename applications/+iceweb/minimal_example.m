%% House cleaning
clc
close all
clear all
warning on
debug.set_debug(100)

%% These are same variables normally defined for a waveform
datasourceObject = datasource('miniseed', '~/Desktop/iceweb_data/wfdata/%s.%s.%s.%s.D.%04d.%03d.miniseed','network','station','location','channel','year','jday');
ChannelTagList = ChannelTag('MV','MTB1','00','HHZ');
startTime = datenum(2018,3,30);
endTime = datenum(2018,3,30,1,0,0);

%% Test the waveform parameters
if 1 % set to 1 to run this part
    clear w
    w = waveform(datasourceObject, ChannelTagList, startTime, min([startTime+1/24 endTime]) );
    if isempty(w)
        disp('No data')
        return
    end
    %plot(w)
    plot_panels(w)
    % plot_helicorder(w)
end

%% Configure IceWeb
%PRODUCTS_TOP_DIR = '/media/sdd1/iceweb_data';
PRODUCTS_TOP_DIR = '~/Desktop/iceweb_data';
subnetName = 'minimal'; % can be anything

% get parameters. these control what iceweb does.
products.DAILYONLY = false; % set true to only produce day plots
iceweb.get_params;
products.waveform_plot.doit = false;
products.rsam.doit = false;
products.rsam.samplingIntervalSeconds = defaultSamplingIntervalSeconds; % [1 60] means record RSAM data at 1-second and 60-second intervals
products.rsam.measures = {'mean'}; % {'max';'mean';'median'} records the max, mean and median in each 1-second and 60-second interval
products.spectrograms.doit = true; % whether to plot & save spectrograms
products.spectrograms.plot_metrics = false; % superimpose metrics on spectrograms
products.spectrograms.timeWindowMinutes = 60; % 60 minute spectrograms. 10 minute spectrograms is another common choice
products.spectral_data.doit = false; % whether to compute & save spectral data
products.soundfiles.doit = false;
products.helicorders.doit = false;
products.reduced.doit = false;
products.reduced.samplingIntervalSeconds = defaultSamplingIntervalSeconds;
products.removeWaveformFiles = false;
products.daily.spectrograms = false;
products.daily.helicorders = false;
products.daily.rsamplots = false;
products.daily.spectralplots = false;
   
%% run IceWeb  ********************** this is where stuff really happens
iceweb.run_iceweb(PRODUCTS_TOP_DIR, subnetName, datasourceObject, ChannelTagList, startTime, endTime, gulpMinutes, products)
