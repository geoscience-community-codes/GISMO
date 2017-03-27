function rsam_wrapper(subnetName, datasourceObject, ChannelTagList, ...
    startTime, endTime, gulpMinutes, samplingIntervalSeconds, measures)
%RSAM_WRAPPER Compute RSAM data for long time intervals
%   rsam_wrapper(subnetName, datasourceObject, ChannelTagList, ...
%       startTime, endTime, gulpMinutes, samplingIntervalSeconds, measures)
%
%   rsam_wrapper(...) is a wrapper designed to move sequentially through
%   days/weeks/months of data, load waveform data into waveform objects,
%   compute RSAM objects from those waveform objects (using waveform2rsam)
%   and then save data from those RSAM objects into binary "BOB" files.
%
%   rsam_wrapper is actually a driver for iceweb_wrapper. iceweb_wrapper
%   will drive other products such as spectrograms and helicorders if
%   asked. But rsam_wrapper asks it only to compute RSAM data.
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
%       gulpMinutes - swallow data in chunks of this size. Minimum is 10
%                     minutes, maximum is 2 hours. Other good choices are
%                     30 minutes and 1 hour.
%
%       samplingIntervalSeconds - compute RSAM with 1 sample from this many
%                             seconds of waveform data. Usually 60 seconds.
%                             See also WAVEFORM2RSAM.
%
%       measures - each RSAM sample is usually the 'mean' of each 60 second
%                  timewindow. But other stats are probably better. For
%                  events, 'max' works better. For tremor, 'median' works
%                  better. So measures could be {'max';'median'}.
%
% Example:
%       datasourceObject = datasource('antelope', '/raid/data/sakurajima/db')
%       ChannelTagList(1) = ChannelTag('JP.SAKA.--.BHZ');
%       ChannelTagList(2) = ChannelTag('JP.SAKB.--.BHZ');
%       startTime = datenum(2015,5,28);
%       endTime = datenum(2015,6,2);
%       gulpMinutes = 10;
%       samplingIntervalSeconds = 60;
%       measures = {'mean'};
%       rsam_wrapper('Sakurajima', datasourceObject, ChannelTagList, ...
%                     startTime, endTime, gulpMinutes, ...
%                     samplingIntervalSeconds, measures) 

% set up products structure for iceweb
products.waveform_plot.doit = true;
products.rsam.doit = true;
products.rsam.samplingIntervalSeconds = samplingIntervalSeconds;
products.rsam.measures = measures;
products.spectrograms.doit = false;

products.spectrograms.timeWindowMinutes = [10 120];
products.spectral_data.doit = false;
products.spectral_data.samplingIntervalSeconds = samplingIntervalSeconds;
products.reduced_displacement.doit = false;
products.reduced_displacement.samplingIntervalSeconds = samplingIntervalSeconds;
products.helicorders.doit = false;
products.helicorders.timeWindowMinutes = [];
products.soundfiles.doit = false;

% call iceweb_wrapper
iceweb.iceweb2017(subnetName, datasourceObject, ChannelTagList, startTime, endTime, gulpMinutes, products)