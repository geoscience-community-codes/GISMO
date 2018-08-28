%% How to run IceWeb on archived data

%% 1. Introduction
%
% It is useful to generate spectrograms, helicorder plots, RSAM data and 
% other products from continuous waveform data. 
%
% This is where we use "IceWeb", an application originally written in 1998
% to process continuous waveform data into a variety of products for
% volcano observatory web pages, to aid rapid recognition of anomalous
% activity. Since we only want RSAM data in this case, we will drive this
% using iceweb.rsam_wrapper. To get help on this, use:
%%
% 
%  help iceweb.iceweb_wrapper
% 

%%
%
% The following is a fully worked example using a Redoubt 2009
% dataset for illustration.
PRODUCTS_TOP_DIR = './iceweb';


%% 2. Setup for the Redoubt 2009 example

%%
% Define datasource - where to get waveform data from
dbpath = fullfile(TESTDATA, 'css3.0', 'demodb')
datasourceObject = datasource('antelope', dbpath)

%% 
% Define the list of channels to get waveform data for
ChannelTagList = ChannelTag.array('AV',{'REF';'RSO'},'','EHZ')

%%
% Set the start and end times
startTime = datenum(2009,3,20,2,0,0)
endTime = datenum(2009,3,23,12,0,0)


%% 3. Call the iceweb_wrapper
iceweb.iceweb_wrapper(PRODUCTS_TOP_DIR, 'Redoubt', datasourceObject, ChannelTagList, ...
            startTime, endTime);
             
%%        
% Note: this may take a long time to run, e.g. 1 week of data for 1
% channel might take about 10 minutes on a desktop computer, reading data
% from a network-mounted drive.

%% 4. Results
% Running this command creates an iceweb directory. Beneath this are:
%
%%
% * waveforms_raw: raw waveform objects saved into MAT files
% * waveforms_clean: cleaned waveform objects, saved into MAT files
% * waveforms_clean_plots: plots of cleaned waveform objects
% * rsam_data: binary bob files with the mean amplitude, median frequency, peak frequency, frequency ratio and frequency index for each 60-s time window
% * spectrograms: 10-minute spectrogram plots
% * spectral_data: an amplitude spectrum for each 10-minute time window. Will be used to generate 24-hour spectrograms later.
%
% AUTHOR NOTES: To be added to this tutorial:
% 
%%
% * Examples of each of the directory structures above.
% * RSAM plots for the whole time series.
% * 24-h spectrograms.
% * 24-h helicorder plots.
%
% These last 2 will be added into iceweb.iceweb_wrapper()