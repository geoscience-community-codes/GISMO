%% Running IceWeb on directory tree of Miniseed files
% In my research groups in Alaska and now Florida, we always tended to
% organize datasets into Antelope CSS3.0 databases. The advantage of this
% is that Antelope then handles all the heavy lifting of loading files,
% which can be in SEED, Miniseed or SAC format, filling gaps, and crossing
% file boundaries. And it does so very efficiently because the Antelope
% programs are compiled C code. 
%
% However, most of the datasets we get directly from instruments are
% directory trees of miniseed data. Until now, GISMO has never had a way to
% easily navigate these directory trees. But now that it does, we have an
% alternative to the having to using miniseed2db to build a wfdisc table.
% This is useful because we do not always have Antelope available, and
% because a wfdisc table often requires directory paths and filenames to be
% shortened. Also, we no longer have to write our own wrappers to navigate
% complex directory structures, as we previously had to to avoid using
% Antelope.
%
% To get a first look at data, however it is structured, it is useful to 
% work through the data in timewindows of 10 minutes to 1 hour, and compute
% RSAM data and make spectrograms. This is what "IceWeb" does. This name
% goes back to a system written at UAFGI/AVO in 1998 that made these sorts
% of plots with real-time data from the AVO seismic network.
%
% Welcome to the first example of running IceWeb on a collection of
% Miniseed files!

%% House cleaning
clc
close all
clear all
warning off

%% These are same variables normally defined for a waveform
% in this case, the files are stored by station & channel & day-of-year
%
% (jday), and they reside in year directories
datasourceObject = datasource('miniseed', '/home/thompsong/shares/newton/data/Montserrat/LaharStudy/%s/%04d/%s/%s/%s.D/%s.%s.%s.%s.D.%04d.%03d.miniseed','station','year','network','station','channel','network','station','location','channel','year','jday')
%
% Multiple network/station/location/channel combinations can be defined
% using ChannelTag.array()
ChannelTagList = ChannelTag.array('MV',{'MTB1';'MTB2';'MTB3';'MTB4'},'00','HHZ');
ChannelTagList2 = ChannelTag.array('MV',{'MTB1';'MTB2';'MTB3';'MTB4'},'10','HDF');
ChannelTagList = [ChannelTagList ChannelTagList2];
clear ChannelTagList2

% startTime = datenum(2018,4,3);
% endTime = datenum(2018,4,4);
startTime = datenum(2018,3,28);
endTime = datenum(2018,7,10);

%% Test the waveform parameters
clear w
w = waveform(datasourceObject, ChannelTagList, startTime, min([startTime+1/24 endTime]) );
if isempty(w)
    disp('No data')
    return
end
plot(w)
plot_panels(w)
% plot_helicorder(w)

%% Configure IceWeb
products_dir = '/media/sdd1/iceweb_data';
network_name = 'Montserrat'; % can be anything
% output directory is products_dir/network_name
%
% set up products structure for iceweb - DO NOT RECOMMEND CHANGING THESE
products.waveform_plot.doit = true;
products.rsam.doit = true;
products.rsam.samplingIntervalSeconds = [1 60]; % [1 60] means record RSAM data at 1-second and 60-second intervals
products.rsam.measures = {'max';'mean';'median'}; % {'max';'mean';'median'} records the max, mean and median in each 1-second and 60-second interval
products.spectrograms.doit = true;
products.spectrograms.timeWindowMinutes = 60; % 60 minute spectrograms. 10 minute spectrograms is another common choice
%products.spectrograms.fmin = 0.5;
products.spectrograms.fmax = 100; % Hz
products.spectrograms.dBmin = 60; % white level
products.spectrograms.dBmax = 120; % pink level
products.spectral_data.doit = true;
products.spectral_data.samplingIntervalSeconds = 60; % spectral data are archived at this interval
%  the following parameters are not really used yet - this functionality
%  has not been added back to IceWeb yet
products.reduced_displacement.doit = false;
products.reduced_displacement.samplingIntervalSeconds = 60;
products.helicorders.doit = true;
products.helicorders.timeWindowMinutes = 10;
products.soundfiles.doit = true;
%
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

% save the parameters we are using to a timestamped mat file
save(sprintf('icewebparams_%s_%s_%s_%s.mat',network_name,datestr(startTime,'yyyymmdd'),datestr(endTime,'yyyymmdd'),datestr(now,30)));

%% run the IceWeb wrapper
% uncomment the following line
iceweb.iceweb2017(products_dir, network_name, datasourceObject, ChannelTagList, startTime, endTime, gulpMinutes, products)