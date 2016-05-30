% Standard clearing MATLAB workspace & command window, closing figures
clc
clear all
close all
warning off

%% 1. INTRODUCTION
% <http://geoscience-community-codes.github.io/GISMO/files/gismo_presentation_ineter2.pdf 1.1 Yesterday's presentation>
%
% <https://github.com/geoscience-community-codes/GISMO/wiki/What-is-GISMO%3F 1.2 What is GISMO?>
%
% <https://github.com/geoscience-community-codes/GISMO/wiki/Who-uses-it%3F 1.3 Who uses it?>
%
% <https://github.com/geoscience-community-codes/GISMO/wiki/Historical-development 1.4 Historical development>
%
% <https://github.com/geoscience-community-codes/GISMO/wiki/object-oriented 1.5 Object-oriented programming terminology>

%% 2. GETTING STARTED
%%
% <https://github.com/geoscience-community-codes/GISMO/wiki/Getting-started Getting started>

%% 3. WAVEFORM DATA

%% 3.1 Reading waveform data
% To retrieve a waveform object, the command is:
%    w = waveform(ds, scnl, starttime, endtime)
% The arguments are:
%%
%
% * ds - a datasource object. This describes where to get the data from.
% * scnl - a scnlobject. This describes the station, channel, network and location code to retrieve.
% * starttime - the start date/time in MATLAB format
% * endtime - the end date/time in MATLAB format
%

%%
% *Reading waveform data from a Miniseed file which contains data from a single station*
ds = datasource('miniseed', fullfile('GISMO_DATA','REF.EHZ.2009.080'));
scnl = scnlobject('REF', 'EHZ');
starttime = datenum(2009,3,21);
endtime=datenum(2009,3,22);
w1 = waveform(ds, scnl, starttime, endtime)

%%
% w1 contains a single waveform object

%%
% *Reading waveform data from a SAC file*
ds = datasource('sac', 'GISMO_DATA/REF.EHZ.2009-03-22T00.00.00.000000Z.sac');
scnl = scnlobject('REF', 'EHZ');
starttime = datenum(2009,3,22);
endtime=datenum(2009,3,23);
w2 = waveform(ds, scnl, starttime, endtime)

%%
% *Reading waveform data from a Seisan file which contains data from multiple stations*
ds = datasource('seisan', 'GISMO_DATA/2001-02-02-0303-55S.MVO___019');
scnl = scnlobject('*', 'BHZ');
starttime = datenum(2001,2,2,03,03,00);
endtime=datenum(2001,2,2,03,23,00);
w3 = waveform(ds, scnl, starttime, endtime)

%%
% w3 is an array of 19 waveform objects

%%
% *Other datasources are:*
%%
% 
% * IRIS DMC - datasource('irisdmcws')
% * Earthworm/Winston waveserver - datasource('winston', 'pubavo1.wr.usgs.gov', 16022)
% * CSS3.0 databases (needs Antelope) - datasource('css3.0', 'path_to_css3_database')
%

%% 3.2 Waveform methods
% For a full list of the methods associated with a waveform object, type:
methods(waveform)

%%
% To get help on any of these, use the help function
help waveform/combine

%%
% We can combine w1 and w2 because although they come from different file
% types (miniseed and sac), they are for the same station & channel and for
% consecutive days
w4 = combine([w1 w2])

%% 3.3 Plotting waveform data
% First let us plot w4, which is a single waveform object
% The simplest type of plot is made with the *plot* method
figure; plot(w4)

%%
% The x-axis is labelled in seconds, which are hard to read. Switch to
% hours.
figure; plot(w4, 'xunit', 'hours')

%%
% Another simple type of plot is a helicorder plot with *plot_helicorder*
% Since w4 contains 2 days of data, let's use 60 minutes per line (mpl)
plot_helicorder(w4, 'mpl', 60)

%%
% Now let us plot w2, which is an array of 19 waveform objects
figure; plot(w3)

%%
% This looks awful!

%%
% We can also use *plot_panels* to put each waveform object in a separate
% panel:
plot_panels(w3([8 11 18]))

%%
% We can also plot spectral data. First plot amplitude spectra:
plot_spectrum(w3([8 11 18]))

%%
% Second, plot spectrograms:
figure; spectrogram(w3([8 11 18]))


%% 3.4 Processing waveform data
% Extract / subset a waveform from a waveform
w5 = extract(w4, 'time', datenum(2009,3,22,20,0,0), datenum(2009,3,22,21,0,0))
figure; spectrogram(w5)
%%
% Plot
figure;
plot(w5)
title('Raw seismogram')

%%
help filterobject
%%
help detrend

%%
% Plot displacement, velocity & acceleration seismograms
figure

ax(1)=subplot(3,1,1);
w5=detrend(w5);
fobj = filterobject('h', 0.5, 2);
w5 = filter(fobj, w5);
plot(integrate(w5))
ylabel('Displacement')

ax(2)=subplot(3,1,2);
plot(w5)
ylabel('Velocity')

ax(3)=subplot(3,1,3); 
plot(diff(w5))
ylabel('Acceleration')

linkaxes(ax,'x')

%%
% Save waveform as an audio file
waveform2sound(w5, 60, 'test.wav');

%%
% Open spectrogram browser for Sakurajima 2015
% <http://vps-geoscience-web1.it.usf.edu/iceweb_php/mosaicMaker.php?subnet=Sakurajima&year=2015&month=05&day=19&hour=00&minute=00&numhours=24&plotsPerRow=4 Sakurajima Spectrograms>
web('http://vps-geoscience-web1.it.usf.edu/iceweb_php/mosaicMaker.php?subnet=Sakurajima&year=2015&month=05&day=20&hour=00&minute=00&numhours=24&plotsPerRow=4')

%% 3.5 Saving waveform data
% Waveform objects can be written to SAC files. However, much easier is
% just to write to MATLAB files:
save REF.EHZ.20090321.mat w4
clear w4

%%
load REF.EHZ.20090321.mat

%% 4. EVENT CATALOGS

%% 4.1 Reading event catalogs


%% 4.2 Processing event catalogs
%% 4.3 Plotting event catalogs
%% 4.4 Event rates
%% 4.5 Saving event catalogs

%% 5. RSAM DATA
%% 5.1 Reading RSAM data from binary files
% For one station we can use an explicit path
dp = 'GISMO_DATA/MOMN2015.DAT';
%%
% But if we want to load several files, we can use a file pattern
dp = 'GISMO_DATA/SSSSYYYY.DAT'; %SSSS means station, YYYY means year
s = rsam.read_bob_file('file', dp, 'snum', datenum(2015,1,1), ...
      'enum', datenum(2015,2,1), 'sta', 'MOMN', 'units', 'Counts')
  
%% 5.2 Plotting RSAM data
s.plot()

%% 5.3 Generating RSAM data from waveform data
w4
r = waveform2rsam(w4)
r.plot()

%% 5.4 Saving RSAM data
% *save to a text file*
r.toTextFile('REF_EHZ_2009.DAT')
%%
% view the text file
type('REF_EHZ_2009.DAT')

%%
% *save to a binary (BOB) file*
r.save('YYYY_SSSS_CCC_MMMM.bob');

%% 6. OTHER THINGS
%% 6.1 sta/lta event detection

% Plot continuous drumplot
plot_helicorder(w5, 'mpl', 5);

%%
% set the STA/LTA detector
sta_seconds = 0.7; % STA time window 0.7 seconds
lta_seconds = 7.0; % LTA time window 7 seconds
thresh_on = 3; % Event triggers "ON" with STA/LTA ratio exceeds 3
thresh_off = 1.5; % Event triggers "OFF" when STA/LTA ratio drops below 1.5
minimum_event_duration_seconds = 2.0; % Trigger must be on at least 2 secs
pre_trigger_seconds = 0; % Do not pad before trigger
post_trigger_seconds = 0; % Do not pad after trigger
event_detection_params = [sta_seconds lta_seconds thresh_on thresh_off ...
    minimum_event_duration_seconds];

%%
% run the STA/LTA detector. lta_mode = 'frozen' means the LTA stops
% updating when trigger is "ON".
[cobj,sta,lta,sta_to_lta] = Detection.sta_lta(w5, 'edp', event_detection_params, ...
    'lta_mode', 'frozen');

%%
% Plot detected events on top of the continuous drumplot
plot_helicorder(w5, 'mpl', 5, 'catalog', cobj)
%h3 = drumplot(w5, 'mpl', 5, 'catalog', cobj);
%plot(h3)

%% 6.2 Reading SAC pole-zero files
%% 6.3 Removing instrument responses
%% 6.4 The correlation cookbook

%% 7. EXAMPLES
%% 7.1 Cleaning waveform data
% Seismic waveform data can have all sorts of problems, including:
%%
% * Spikes (outliers)
% * Dropouts (missing data)
% * Irregular sample intervals
% * Drift (trends)
% * Noise

%%
% 
clear ax
close all
figure
ax(1) = subplot(3,2,1); plot(w5); title('raw')
hold on

%%
% load a waveform object that has many problems
w6 = messitup(w5);
ax(2) = subplot(3,2,2); plot(w6); title('messed up')

%%
% remove spikes with a median filter
w6 = medfilt1(w6, 3);
ax(3) = subplot(3,2,3); plot(w6); title('despiked')

%%
% in case there are gaps in the time series (marked by NaN) we can interpolate a
% meaningful value
w6 = fillgaps(w6, 'interp');
ax(4) = subplot(3,2,4); plot(w6); title('interpolated')
%%
% detrend the time series - this removes linear drift
w6 = detrend(w6);
ax(5) = subplot(3,2,5); plot(w6); title('detrended')

%%
% band pass filter to enhance signal to noise
% create a Butterworth bandpass filter from 0.5 to 15 Hz, 2 poles
fobj = filterobject('b', [0.5 15], 2);

%%
% apply the filter in both directions (acausal) - this is a zero phase
% filter which is helpful because it doesn't disperse different frequency
% components. the caveat is that it can spread energy so arrivals may appear
% slighter earlier than they actually are
w6 = filtfilt(fobj, w6);
ax(6) = subplot(3,2,6); plot(w6); title('filtered')
linkaxes(ax,'x');

%%
figure;
clear ax
ax(1)=subplot(2,1,1); plot(w5)
ax(2)=subplot(2,1,2); plot(w6)
linkaxes(ax,'x')




