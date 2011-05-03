function SCNLs = scnlobject(stations, channels, network, location)
% scnl : object that holds the station, channel, network, and location for
% a seismic trace.  This object is used by the datasource object.
%
%  scnl = scnlobject(station, channel, network, location);
%  scnl = scnlobject(); %default, blank scnl
%  scnls = scnlobject(station, channels, network, location);
%  scnls = scnlobject(stations, channel, network, location);
%
%  note, you can either assign multiple channels to a station or assign
%  multiple stations with a single channel, not both.
%
%
%  ----------- WILDCARDS ---------------------
%  scnlobject is merely a storage unit for net-sta-chan-loc information. It
%  is blind to wildcards. However, when used as an argument in WAVEFORM,
%  wildcards in the scnlobject take on meaning that depends somewhat on the
%  DATASOURCE type. In most cases, * wildcards are understood without 
% issue. 
% 
%  scnlobject('R*','BHZ','XE','') match all stations begining with R
%  scnlobject('MCK','*','XE','')  match all channels for MCK
%  scnlobject('R*','*','XE','')   all R* stations. All channels
%
%  The uses above have been tested against Antelope data sources. Note that
%  in Antelope it would be more common to use the literal wildcards 'R.*' 
%  or '.*'. When waveform interprets scnlobjects, it considers these use
%  the same.
%
%  Be careful what you ask for. Wildcards can return very large amounts of
%  data!



switch (nargin)
  case 0 %default
  case 4 %station, channel, network, location
  case 3 %station, channel, network
  case 2 %station, channel
  otherwise
    error(nargchk(2, 4, nargin, 'struct'));
end

% initialize defaults
defaultStation = '';
defaultChannel = '';
defaultNetwork = '--';
defaultLocation = '--';

% assign default if it seems appropriate
if ~exist('stations','var') || isempty(stations)
  stations = defaultStation;
end
if ~exist('channels','var') || isempty(channels)
  channels = defaultChannel;
end
if ~exist('network','var') || isempty(network)
  network = defaultNetwork;
end
if ~exist('location','var') || isempty(location)
  location = defaultLocation;
end
% 
% %handle multiple stations or channels
% if iscell(station)
%   if iscell(channel),
%     warning('SCNL:multipleStationsAndChannels',...
%       'because multiple stations were specified, the multiple channels were ignored');
%     channel = channel{1};
%   end
%   scnl(numel(station)) = scnlobject(); %preallocate
%   for i=1:numel(station)
%     % station = unique(station); %note, station will be sorted!
%     scnl(i) = scnlobject(station{i},channel,network,location);
%   end
%     return
% end
% 
% if iscell(channel)
%   % channel = unique(channel); %note, channel will be sorted!
%   
%   scnl(numel(channel)) = scnlobject(); %preallocate
%   for i=1:numel(channel)
%     scnl(i) = scnlobject(station,channel{i},network,location);
%   end
%     return
% end

%following from toSNL in waveform
%SCNLs = scnlobject(stations,channels,network,location);
%return;

if ~iscell(stations), stations=  {stations}; end;
if ~iscell(channels), channels= {channels}; end;
nStations = numel(stations);
nChannels = numel(channels);

if nChannels == nStations
  for i=1:nStations
    SCNLs(i) = singleSCNL(stations{i},channels{i},network,location);
  end
elseif(nStations == 1 && nChannels > 1)
  %single station, multiple channels
  for i=1:nChannels
    SCNLs(i) = singleSCNL(stations{1},channels{i},network,location);
  end
elseif (nChannels == 1 && nStations > 1)
  %single channel, multiple stations
  for i=1:nStations
    SCNLs(i) = singleSCNL(stations{i},channels{1},network,location);
  end
else
  error('invalid combination (number) of stations and channels to create a SCNL');
end

function scnl = singleSCNL(station, channel, netwk, location)
scnl.station = station;
scnl.channel = channel;
scnl.network = netwk;
scnl.location = location;
scnl = class(scnl,'scnlobject');
