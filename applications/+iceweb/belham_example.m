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
debug.set_debug(100)

%% These are same variables normally defined for a waveform
% in this case, the files are stored by station & channel & day-of-year
%
% (jday), and they reside in year directories
%datasourceObject = datasource('miniseed', '/home/thompsong/shares/newton/data/Montserrat/LaharStudy/%s/%04d/%s/%s/%s.D/%s.%s.%s.%s.D.%04d.%03d.miniseed','station','year','network','station','channel','network','station','location','channel','year','jday')
%datasourceObject = datasource('miniseed', '/Volumes/data/Montserrat/LaharStudy/%s/%04d/%s/%s/%s.D/%s.%s.%s.%s.D.%04d.%03d.miniseed','station','year','network','station','channel','network','station','location','channel','year','jday')
datasourceObject = datasource('miniseed', '~/Desktop/iceweb_data/wfdata/%s.%s.%s.%s.D.%04d.%03d.miniseed','network','station','location','channel','year','jday');
%
% Multiple network/station/location/channel combinations can be defined
% using ChannelTag.array()
ChannelTagList = ChannelTag.array('MV',{'MTB1';'MTB2';'MTB3';'MTB4'},'00','HHZ');
ChannelTagList2 = ChannelTag.array('MV',{'MTB1';'MTB2';'MTB3';'MTB4'},'10','HDF');
ChannelTagList = [ChannelTagList ChannelTagList2];
clear ChannelTagList2

% startTime = datenum(2018,4,3);
% endTime = datenum(2018,4,4);
startTime = datenum(2018,3,30);
endTime = datenum(2018,3,31);

%% Test the waveform parameters
% clear w
% w = waveform(datasourceObject, ChannelTagList, startTime, min([startTime+1/24 endTime]) );
% if isempty(w)
%     disp('No data')
%     return
% end
% plot(w)
% plot_panels(w)
% % plot_helicorder(w)

%% Configure IceWeb
%products_dir = '/media/sdd1/iceweb_data';
products_dir = '~/Desktop/iceweb_data';
network_name = 'Montserrat'; % can be anything
% output directory is products_dir/network_name
%
% set up products structure for iceweb - DO NOT RECOMMEND CHANGING THESE
products.waveform_plot.doit = true;
products.rsam.doit = true;
products.rsam.samplingIntervalSeconds = [1 60]; % [1 60] means record RSAM data at 1-second and 60-second intervals
products.rsam.measures = {'max';'mean';'median'}; % {'max';'mean';'median'} records the max, mean and median in each 1-second and 60-second interval
products.spectrograms.doit = true; % whether to plot & save spectrograms
products.spectrograms.plot_metrics = true; % superimpose metrics on spectrograms
products.spectrograms.timeWindowMinutes = 60; % 60 minute spectrograms. 10 minute spectrograms is another common choice
%products.spectrograms.fmin = 0.5;
products.spectrograms.fmax = 100; % Hz
products.spectrograms.dBmin = 60; % white level
products.spectrograms.dBmax = 120; % pink level
products.spectral_data.doit = true; % whether to compute & save spectral data
products.spectral_data.samplingIntervalSeconds = 60; % DO NOT CHANGE! spectral data are archived at this interval
%  the following parameters are not really used yet - this functionality
%  has not been added back to IceWeb yet
products.reduced_displacement.doit = true;
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

%%
% save the parameters we are using to a timestamped mat file
save(sprintf('icewebparams_%s_%s_%s_%s.mat',network_name,datestr(startTime,'yyyymmdd'),datestr(endTime,'yyyymmdd'),datestr(now,30)));

%% run the IceWeb wrapper
% uncomment the following line
iceweb.iceweb2017(products_dir, network_name, datasourceObject, ChannelTagList, startTime, endTime, gulpMinutes, products)

%% Daily plots
close all; clc
% ctags(1) = ChannelTag('MV','MTB1','00','HHZ');
% ctags(2) = ChannelTag('MV','MTB1','10','HDF');
% ctags(3) = ChannelTag('MV','MTB2','00','HHZ');
% ctags(4) = ChannelTag('MV','MTB2','10','HDF');
% ctags(5) = ChannelTag('MV','MTB3','00','HHZ');
% ctags(6) = ChannelTag('MV','MTB3','10','HDF');
% ctags(7) = ChannelTag('MV','MTB4','00','HHZ');
% ctags(8) = ChannelTag('MV','MTB4','10','HDF');

flptrn = fullfile(products_dir,'MV',network_name,'YYYY-MM-DD','spdata.NSLC.YYYY.MM.DD.max');

for snum=floor(startTime):ceil(endTime-1)
    enum = ceil(endTime)-eps;
    
    % DAILY SPECTROGRAMS
    iceweb.plot_day_spectrogram('', flptrn, ChannelTagList, snum, enum);
    dstr = datestr(snum,'yyyy-mm-dd');
    daysgrampng = fullfile(products_dir,'MV',network_name,dstr,sprintf('daily_sgram_%s.png',dstr));
    print('-dpng',daysgrampng);

    % RSAM plots for max, mean, median
    measures = {'max';'mean';'median'};
    filepattern = fullfile(products_dir,'MV',network_name,'SSSS.CCC.YYYY.MMMM.060.bob');
    for k=1:numel(measures)
        plot_day_rsam(filepattern, snum, enum, ChannelTagList, measures{k});
        pngfile = fullfile(products_dir,'MV',network_name,dstr,sprintf('daily_rsam_%s_%s.png',measures{k},dstr));
        print('-dpng',pngfile);
    end
    
    % SPECTRAL METRICS PLOTS
    measures = {'findex';'fratio';'meanf';'peakf'};
    filepattern = fullfile(products_dir,'MV',network_name,'SSSS.CCC.YYYY.MMMM.bob');
    for k=1:numel(measures)
        plot_day_rsam(filepattern, snum, enum, ChannelTagList, measures{k});
        pngfile = fullfile(products_dir,'MV',network_name,dstr,sprintf('daily_%s_%s.png',measures{k},dstr));
        print('-dpng',pngfile);
    end    
   
end

%%

function plot_day_rsam(filepattern, snum, enum, ctag, measure)
    for c=1:numel(ctag)
        r(c) = rsam.read_bob_file(filepattern, 'snum', snum, 'enum', enum, 'sta', ctag(c).station, 'chan', ctag(c).channel, 'measure', measure, 'units', 'Hz')
    end
    r.plot_panels();
end

%% TO DO
% 1. Calibrations
% 2. Check options work
% 3. Add option to remove normal spectrograms
% 4. Add option to remove waveform files
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
% 10. Put the big overlap back intro spectrograms?
% 11. Add ability not to reprocess same data (just add if new products
% selected)
% 12. Re-add my diagnostic data analysis tools
% 13. Amplitude Location tool
