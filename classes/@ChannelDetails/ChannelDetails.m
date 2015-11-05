classdef ChannelDetails
   %ChannelDetails Handles station metadata information
   %   Access fields as though this were a struct
   %
   %  Request data using
   %  ChannelDetails.retrieve([], ...) retrieve data from default source:
   %    https://service.iris.edu/fdsnws/station/1/
   %  What follows are parameter-value pairs that filter which data is
   %  retrieved.  These are described in detail from the iris website
   %   <a href>https://service.iris.edu/fdsnws/station/1/</a>
   %
   %  Examples:
   %    Ex 1. Retrieve all stations that start with A, for network IU. But
   %    only the BH channels (excluding BHZ)
   %    ChannelDetails.retrieve([],'station','A*','network','IU','channel','BH?,-BHZ')
   %
   %    Ex 2. Retrieve channel detail for a SeismicTrace
   %    T = SeismicTrace; T.name = 'IU.ANMO.00.BHZ'; T.starttime = now-1;
   %    ChannelDetails.retrieve([],T);
   %
   %    Ex 3. Retrieve channel detail for ChannelTag (all channels)
   %    ct = ChannelTag('IU.ANMO.00..');
   %    ChannelDetails.retreive([],ct); % results returned in a
   %
   %    Results are in an 1XN ChannelDetails object
   
   % NOTE: Starting in r2014b matlab has WEBREAD to access data from
   % restful services.  We could use that with weboptions to provide useful
   % information to the service. (such as type of data requested, useragent,
   % and for restricted data, a username & password pair.
   
   properties(Dependent)
      name
      network
      station
      location
      channel
   end
   
   properties
      channelinfo
      latitude
      longitude
      elevation
      depth
      azimuth
      dip
      sensordescription
      scale
      scalefreq
      scaleunits
      samplerate
      starttime
      endtime
   end
   
   properties(Dependent, Hidden)
      latlon
      latlonelev
   end
   
   methods
      %% get/set of channel-related data
      function N = get.network(obj)
         N = obj.channelinfo.network;
      end
      function obj = set.network(obj, val)
         obj.channelinfo.network = val;
      end
      
      function S = get.station(obj)
         S = obj.channelinfo.station;
      end
      function obj = set.station(obj, val)
         obj.channelinfo.station = val;
      end
      
      function L = get.location(obj)
         L = obj.channelinfo.location;
      end
      function obj = set.location(obj, val)
         obj.channelinfo.location = val;
      end
      
      function C = get.channel(obj)
         C = obj.channelinfo.channel;
      end
      function obj = set.channel(obj, val)
         obj.channelinfo.channel = val;
      end
      
      function S = get.name(obj)
         S = obj.channelinfo.string;
      end
      function C = getbyname(obj,val)
         % getbyname does not know wildcards!
         % retrieves values that match requeste Net.Sta.Loc.Cha name
         % ex.
         % chandeets.getbyname('IU.ANMO.00.BH1')
         C = obj(strcmp({obj.name},val));
      end
      function LL = get.latlon(obj)
         % handles single lat/lon combination
         LL = [obj.latitude, obj.longitude];
      end
      function obj = set.latlon(obj, LL)
         % handles single lat/lon combination
         %does no reality checks
         assert(numel(LL) == 2);
         obj.latitude = LL(1);
         obj.longitude = LL(2);
      end
     function LL = latlons(obj)
        % can handle multiple latitudes & longitudes
         LL = [[obj.latitude]' [obj.longitude]'];
     end
     
     function [hSta, hLine,nameList] = sphereplot(obj)
        % sphereplot plots the stations on a sphere that represents the
        % earth.
        %
        % example:
        % % grab all BHZ stations in iris catalog, then plot
        % chandeets = ChannelDetails.retrieve([],'channel','BHZ','endafter',datenum(2015,1,1));
        % chandeets.sphereplot;
        %
        % TODO: add color or symbol per object?
        [sphx,sphy,sphz] = sphere(36);
        s=surf(sphx,sphy,sphz,'FaceAlpha',0.7,'edgecolor',[0.85 0.85 0.85],'FaceColor',[1, 1, 1]);
        
        deg2rad = @(x) (pi / 180) .* x;
        LatLon = deg2rad(obj.latlons);
        [x,y,z] = sph2cart(LatLon(:,2), LatLon(:,1),1.05);
        set(gca,'ytick',[],'xtick',[],'ztick',[]);
        hold on;
        hSta = scatter3(x,y,z,[],'b','filled'); %allows recoloring individually
        [x2,y2,z2] = sph2cart(LatLon(:,2), LatLon(:,1),1.0);
        hLine = plot3([x,x2]',[y,y2]',[z,z2]','k-'); %plot dashes above
        hold off
        axis equal
        axis vis3d
        grid off
        nameList = {obj.name};
     end
   end
   methods(Static)
      function chdeets = retrieve(ds,varargin)
         % get from fdsnws station service
         % ds not used (yet)
         if numel(varargin) == 1
            switch(class(varargin{1}))
               case 'char'
                  chdeets = ChannelDetails.retrieve(ds,ChannelTag(varargin{1}));
                  return
               case {'SeismicTrace'}
                  for n=numel(varargin{1}):-1:1
                     me = varargin{1}(n);
                     ch = ChannelDetails.retrieve(ds,...
                        'network',me.network, 'station', me.station, ...
                        'location', me.location, 'channel', me.channel, ...
                        'starttime', me.firstsampletime, 'endtime', me.lastsampletime);
                     if numel(ch) > 1
                        warning('Found multiple epochs for %s channel. only Keeping last one', me.name);
                     end
                     chdeets(n) = ch(end);
                  end
                  chdeets = reshape(chdeets, size(varargin{1}));
                  return
               case 'ChannelTag'
                  % return as cell, because we can't be sure how many are
                  % returned!
                  if numel(varargin{1}) == 1
                     me = varargin{1};
                     chdeets = ChannelDetails.retrieve(ds, ...
                        'network',me.network, 'station', me.station, ...
                        'location', me.location, 'channel', me.channel);
                  else
                     for n=numel(varargin{1}):-1:1
                        me = varargin{1}(n);
                        chdeets(n) = { ChannelDetails.retrieve(ds, ...
                           'network',me.network, 'station', me.station, ...
                           'location', me.location, 'channel', me.channel)};
                     end
                     chdeets = reshape(chdeets, size(varargin{1}));
                  end
                  return
               otherwise
                  error('Unknown usage');
            end
         end
         p = inputParser;
         p.addOptional('network','');
         p.addOptional('station','');
         p.addOptional('channel','');
         p.addOptional('location','');
         p.addOptional('starttime',[]);
         p.addOptional('endtime',[]);
         p.addOptional('startbefore',[]);
         p.addOptional('startafter',[]);
         p.addOptional('endbefore',[]);
         p.addOptional('endafter',[]);
         p.addOptional('minlat',[]);
         p.addOptional('maxlat',[]);
         p.addOptional('minlon',[]);
         p.addOptional('maxlon',[]);
         p.addOptional('lat',[])
         p.addOptional('lon',[]);
         p.addOptional('maxradius',[]);
         p.addOptional('minradius',[]);
         p.addOptional('sensor',[]);
         p.addOptional('includerestricted','');
         p.addOptional('includeavailability','');
         p.addOptional('updatedafter','');
         p.addOptional('matchtimeseries','');
         p.parse(varargin{:})
         R = p.Results;
         fn = fieldnames(R);
         urlstr = 'https://service.iris.edu/fdsnws/station/1/query?format=text&level=channel';
         for n=1:numel(fn) % make sure we keep only active fields
            f = fn{n}; v = R.(f);
            if isempty(v)
               R = rmfield(R,f);
            else
               switch(f)
                  case {'network','channel','location','station'}
                     % all strings, nothing to do
                  case {'starttime','endtime',...
                        'startbefore','endbefore',...
                        'startafter','endafter',...
                        'updatedafter'}
                     if ischar(v)
                        R.(f) = datestr(datenum(v),31);
                     elseif isnumeric(v)
                        %datenum
                        R.(f) = datestr(v,31);
                     end
                     R.(f) = strrep(R.(f),' ','T');
                     % all dates. further process
                  case {'lat', 'lon', 'maxradius', 'minradius'}
                     assert(~any(ismember({'minlat','maxlat','minlon','maxlon'},fn)),...
                        'cannot describe with lat/lon and min/max lat/lon');
                     R.(f) = num2str(v);
                  case {'minlat','maxlat','minlon','maxlon'}
                     R.(f) = num2str(v);
                  case {'includerestricted', 'includeavailability', 'matchtimeseries'}
                     % translate into 'TRUE' and 'FALSE'
               end
            end
         end
         fnames = fieldnames(R);
         for n=1:numel(fnames)
            name = fnames{n};
            val = R.(name);
            urlstr = [urlstr, '&', name, '=', val];
         end
         disp(urlstr)
         chdeets = urlread(urlstr);
         labels = textscan(chdeets,'%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s',1,'delimiter','|');
         labels=[labels{:}];
         labels(1) = {labels{1}(2:end)}; %first label starts with #;
         labels = lower(strtrim(labels));
         C = textscan(chdeets,'%s %s %s %s %f %f %f %f %f %f %s %f %f %s %f %s %s','delimiter','|','commentstyle','#');
         
         % convert station network channel location to channeltags and clean
         chanTags = ChannelTag(strcat(...
            C{strcmp(labels,'network')},'.',...
            C{strcmp(labels,'station')},'.',...
            C{strcmp(labels,'location')},'.',...
            C{strcmp(labels,'channel')}));
         C{1} = chanTags; C(2:4) = [];
         labels{1} = 'channelinfo'; labels(2:4)=[];
         % clean up time fields, and convert
         timefields = find(ismember(labels,{'starttime','endtime'}));
         for n=timefields
            C{n} = datenum(strrep(C{n},'T',' '));
         end
         % parse it
         clear chdeets
         for n=1:numel(chanTags)
            chdeets(n) = ChannelDetails;
            for x = 1 : numel(labels);
               fn = labels{x};
               if iscell(C{x})
                  thisval = C{x}{n};
               else
                  thisval = C{x}(n);
               end
               chdeets(n).(fn) = thisval;
            end
         end
      end
   end
   
end

