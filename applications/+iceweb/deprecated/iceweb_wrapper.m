function iceweb_wrapper(PRODUCTS_TOP_DIR, subnetName, datasourceObject, ChannelTagList, ...
    startTime, endTime)
%ICEWEB_WRAPPER Run IceWeb for long time intervals
%   iceweb_wrapper(subnetName, datasourceObject, ChannelTagList, ...
%       startTime, endTime)
%
%   iceweb_wrapper(...) is a wrapper designed to move sequentially through
%   days/weeks/months of data, load waveform data into waveform objects,
%   compute various IceWeb products from those waveform objects
%   and save data into binary "BOB" files.
%
%   Inputs:
%
%       subnetName - (string) usually the name of a volcano
%
%       datasourceObject - (datasource) tells waveform where to load data
%                          from (e.g. IRIS, Earthworm, Antelope, Miniseed). 
%                          See WAVEFORM, DATASOURCE.
%       
%       ChannelTagList - (ChannelTag.array) tells waveform which
%                        network-station-location-channel combinations to
%                        load data for. See CHANNELTAG.
%
%       startTime - the date/time to begin at in datenum format. See
%                   DATENUM.
%
%       endTime - the date/time to end at in datenum format. See
%                   DATENUM.
%
% See also: iceweb.iceweb2017

% set up products structure for iceweb
products.waveform_plot.doit = true;
products.rsam.doit = true;
products.rsam.samplingIntervalSeconds = [1 60];
products.rsam.measures = {'max';'mean';'median'};
products.spectrograms.doit = true;
products.spectrograms.timeWindowMinutes = 10;
%products.spectrograms.fmin = 0.5;
products.spectrograms.fmax = 10; % Hz
products.spectrograms.dBmin = 60; % white level
products.spectrograms.dBmax = 120; % pink level
products.spectral_data.doit = true;
products.spectral_data.samplingIntervalSeconds = 60;
products.reduced_displacement.doit = false;
products.reduced_displacement.samplingIntervalSeconds = 60;
products.helicorders.doit = true;
products.helicorders.timeWindowMinutes = 10;
products.soundfiles.doit = true;

gulpMinutes = products.spectrograms.timeWindowMinutes;

global TZ
TZ = 0;


save icewebparams.mat

% call iceweb_wrapper
tic;
iceweb.iceweb2017(PRODUCTS_TOP_DIR, subnetName, datasourceObject, ChannelTagList, startTime, endTime, gulpMinutes, products)
toc

% % create 24h spectrograms
% if products.spectral_data.doit
%     iceweb.make_24h_spectrograms(subnetName, ChannelTagList, startTime, endTime);
% end
% 
% % create 24h helicorders
% if products.helicorders.doit
%     iceweb.make_24h_helicorders(subnetName, ChannelTagList, startTime, endTime);
% end

disp('COMPLETED')
