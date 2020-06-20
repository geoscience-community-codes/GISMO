function products=kathryn_example()

%% House cleaning
clc
close all
warning on
debug.set_debug(0)

%% These are same variables normally defined for a waveform
% Define datasource - where to get waveform data from
datasourceObject = datasource('miniseed', '/raid/data/BlackCanyonCreek/SR4/DAYS/%s/%s.X3..%s.2018.%03d', 'station', 'station', 'channel','jday')

%% 
% Define the list of channels to get waveform data for
ChannelTagList = ChannelTag.array('X3','FES17','',{'EH1','EH2','EHZ'})

%%
% Set the start and end times
startTime = datenum([2018,07,14,0,0,0])
endTime = datenum([2018,07,16,0,0,0])

%% Define calibration information
iceweb.usf_calibrations;
calibObjects(1)

%% Test the waveform parameters
%iceweb.waveform_call_test;

%% Configure IceWeb
PRODUCTS_TOP_DIR = './iceweb_FLOODS_MORE';
subnetName = 'FES17';
% output directory is PRODUCTS_TOP_DIR/network_name/subnetName

% get parameters. these control what iceweb does.
products.minimal = true; % set true to only produce day plots
iceweb.get_params;
products.spectrograms.fmax = 40; % Hz
products.spectrograms.dBmin = 10; % white level
products.spectrograms.dBmax = 105; 
   
% %% run IceWeb  ********************** this is where stuff really happens
iceweb.run_iceweb(PRODUCTS_TOP_DIR, subnetName, datasourceObject, ...
    ChannelTagList, startTime, endTime, gulpMinutes, products, calibObjects)


end
