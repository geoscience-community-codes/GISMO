function belham_example()
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
warning on
debug.set_debug(0)

%% These are same variables normally defined for a waveform
% in this case, the files are stored by station & channel & day-of-year
%
% (jday), and they reside in year directories
%datasourceObject = datasource('miniseed', '/home/thompsong/shares/newton/data/Montserrat/LaharStudy/%s/%04d/%s/%s/%s.D/%s.%s.%s.%s.D.%04d.%03d.miniseed','station','year','network','station','channel','network','station','location','channel','year','jday')
%datasourceObject = datasource('miniseed', '/Volumes/data/Montserrat/LaharStudy/%s/%04d/%s/%s/%s.D/%s.%s.%s.%s.D.%04d.%03d.miniseed','station','year','network','station','channel','network','station','location','channel','year','jday')
% datasourceObject = datasource('miniseed', ...
%     '~/Desktop/iceweb_data/wfdata/%s.%s.%s.%s.D.%04d.%03d.miniseed', ...
%     'network','station','location','channel','year','jday');
datasourceObject = datasource('miniseed', '/media/sdb1/belhamstudy/download2/%s/%04d/%s/%s/%s.D/%s.%s.%s.%s.D.%04d.%03d.miniseed','station','year','network','station','channel','network','station','location','channel','year','jday')


%
% Multiple network/station/location/channel combinations can be defined
% using ChannelTag.array()
ChannelTagList = ChannelTag.array('MV',{'MTB1';'MTB2';'MTB3';'MTB4'},'00','HHZ');
ChannelTagList2 = ChannelTag.array('MV',{'MTB1';'MTB2';'MTB3';'MTB4'},'10','HDF');
ChannelTagList = [ChannelTagList ChannelTagList2];
clear ChannelTagList2

% startTime = datenum(2018,4,3);
% endTime = datenum(2018,4,4);
% startTime = datenum(2018,3,30);
% endTime = datenum(2018,7,12,0,0,0);
startTime = datenum(2018,3,30);
endTime = datenum(2019,1,10);
%% Define calibration information
iceweb.usf_calibrations;

%% Test the waveform parameters
% iceweb.waveform_call_test;

%% Configure IceWeb
%PRODUCTS_TOP_DIR = '/media/sdb1/belhamstudy/icewebproducts';
PRODUCTS_TOP_DIR = 'shares/newton/data/Montserrat/iceweb';
%PRODUCTS_TOP_DIR = '~/Desktop/iceweb_data';
subnetName = 'Monty'; % can be anything
% output directory is PRODUCTS_TOP_DIR/network_name/subnetName

% get parameters. these control what iceweb does.
products.DAILYONLY = false; % set true to only produce day plots
iceweb.get_params;

   
%%
% save the parameters we are using to a timestamped mat file
save(sprintf('icewebparams_%s_%s_%s_%s.mat',subnetName, ...
    datestr(startTime,'yyyymmdd'),datestr(endTime,'yyyymmdd'),datestr(now,30)));

%% run IceWeb  ********************** this is where stuff really happens
iceweb.run_iceweb(PRODUCTS_TOP_DIR, subnetName, datasourceObject, ...
    ChannelTagList, startTime, endTime, gulpMinutes, products, calibObjects)

%% TO DO
% 1. Calibrations DONE
% 2. Check options work
% 3. Add option to remove normal spectrograms DONE. Use DAILYONLY
% 4. Add option to remove waveform files      DONE. Use removeWaveformFiles
% (Which of 3 and 4 use the most space?)
% 5. Generate HTML5 (+JS?) - or use a light PHP server?
%  - different time scales
%    - month browser, RSAM & spectral metrics only
%    - day browser, different products (above + daily spectrograms &
%      helicorders)
%    - hour browser, spectrograms (& helicorders too?) similar to PhP
%    - 5 minute spectrograms browser but show 3 at a time (Chris Nye's suggestion)
% 6. Add colorbar and legend
% 7. Add helicorder plots (ensure adjacent lines are different colors)
% 8. Add tremor alarm 
% 9. Add shorter spectrograms too (e.g. 5 minutes)
% 10. Put the big overlap back into spectrograms?
% 11. Add ability not to reprocess same data (just add if new products
% selected)
% 12. Re-add my diagnostic data analysis tools
% 13. Amplitude Location tool
end
