function SCNLs = scnlobject(stations, channels, networks, locations)
   % scnl : object that holds the station, channel, network, and location for
   % a seismic trace.  This object is used by the datasource object.
   %
   %  scnl = scnlobject(station, channel, network, location);
   %  scnl = scnlobject(); %default, blank scnl
   %  scnls = scnlobject(stations, channels, networks, locations);
   %  scnls = scnlobject(stations, channels, networks, locations);
   %
   %  NOTE: When using combination of stations, channels, networks, locations
   %        Inputs are expected to match in size and shape.  Example
   %        
   %        valid examples: 
   %            s = {'OKCF','OKSO','OKER'}
   %           c = {'EHZ', 'BHZ', 'EHZ'}
   %           scnlobject(s, c, 'AV', '--');
   %           % creates: AV.OKCF..EHZ     AV.OKSO..BHZ    AV.OKER..EHZ
   %
   %           scnlobjects ('ANMO', {'BHZ','BH1','BH2'}, 'IU', '00')
   %           % creates: IU.ANMO.00.BHZ   IU.ANMO.00.BH1  IU.ANMO.00.BH2
   %
   %           scnlobject(({'ANMO','ANTO'},{'BHZ','BHE'},'IU', {'00','10'})
   %           % creates: IU.ANMO.00.BHZ  IU.ANTO.10.BHE
   %
   %        invalid: 
   %           scnlobject({'OKCF','OKSO'}, {'EHZ';'SHZ'}, 'AV', '--'); % wrong shape
   %
   %           s = {'ANMO', 'ANTO'};    
   %           c = {'BHZ', 'BH1', 'BH2'};
   %           scnlobject(s, c, 'IU', '00') % number of elements do not match
   %
   %  ----------- WILDCARDS ---------------------
   %  scnlobject is merely a storage unit for net-sta-chan-loc information. It
   %  is blind to wildcards. However, when used as an argument in WAVEFORM,
   %  wildcards in the scnlobject take on meaning that depends somewhat on the
   %  DATASOURCE type. In most cases, * wildcards are understood without
   %  issue. Note that '*' differs from ''. The latter excludes this term from
   %  the search altogether. Station and channel cannot be excluded from the
   %  search.
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
      case 1 %waveform % Added by Glenn Thompson 2014/10/15 (removed by celso 2015-07-31)
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
