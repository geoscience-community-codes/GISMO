function SCNLs = scnlobject(stations, channels, networks, locations)
   % scnl (deprecated) : object that holds the station, channel, network, and location for
   % a seismic trace.  This object is used by the datasource object.
   % SCNLOBJECT has been replaced by CHANNELTAG
   %
   % scnlobject is now just a backwards-compatibility wrapper for channeltag
   % 
   % see channeltag

   
   switch (nargin)
      case 0 %default
      case 4 %station, channel, network, location
      case 3 %station, channel, network
      case 2 %station, channel
      case 1 %waveform % Added by Glenn Thompson 2014/10/15 (removed by celso 2015-07-31)
         if isa(stations,'channeltag')
            % create from one or more channeltags.
            for i = numel(stations): -1 : 1
               SCNLs(i).tag = stations(i);
            end
            SCNLs = class(SCNLs,'scnlobject');
            return
         end
         error('please use waveform''s get(w,''scnlobject'')');
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
   if ~exist('networks','var') || isempty(networks)
      networks = defaultNetwork;
   end
   if ~exist('locations','var') || isempty(locations)
      locations = defaultLocation;
   end
   
   if  any(cellfun(@iscell,{networks,stations,locations,channels}))
      % we're building an array of SCNLs pass work off to channeltag
      all_tags = channeltag.array(networks,stations,locations,channels);
      for i = numel(all_tags) : -1 : 1
         SCNLs(i).tag = all_tags(i);
      end
      SCNLs = class(SCNLs,'scnlobject');
   else
      SCNLs = singleSCNL(stations, channels, networks, locations);
   end
   
end

function scnl = singleSCNL(sta, cha, net, loc)
   scnl.tag = channeltag(net, sta, loc, cha);
   scnl = class(scnl,'scnlobject');
end
