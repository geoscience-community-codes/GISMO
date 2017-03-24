function iceweb_wrapper(subnetName, datasourceObject, ChannelTagList, ...
    startTime, endTime, gulpMinutes, products)
%ICEWEB_WRAPPER Run IceWeb for long time intervals
%   iceweb_wrapper(subnetName, datasourceObject, ChannelTagList, ...
%       startTime, endTime, gulpMinutes, products)
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
%       gulpMinutes - swallow data in chunks of this size. Minimum is 10
%                     minutes, maximum is 2 hours. Other good choices are
%                     30 minutes and 1 hour.
%
%       products - a structure telling IceWeb which products to generate.
%                  If not explicitly given, it will look like:
%                 products.rsam.doit = true;
%                 products.rsam.samplingIntervalSeconds = samplingIntervalSeconds;
%                 products.rsam.measures = measures;
%                 products.spectrograms.doit = true;
%                 products.spectrograms.timeWindowMinutes = [10 120];
%                 products.spectral_data.doit = true;
%                 products.spectral_data.samplingIntervalSeconds = samplingIntervalSeconds;
%                 products.reduced_displacement.doit = true;
%                 products.reduced_displacement.samplingIntervalSeconds = samplingIntervalSeconds;
%                 products.helicorders.doit = true;
%                 products.helicorders.timeWindowMinutes = [120];
%                 products.soundfiles.doit = true;

%startup_iceweb
matfile = sprintf('%s.mat',subnetName);
PARAMS = struct('max_number_scnls', 8, ...
    '

paths = struct(
iceweb.iceweb_2017(subnetName, datasourceObject, ChannelTagList, ...
    startTime, endTime, gulpMinutes, products, PARAMS, paths);