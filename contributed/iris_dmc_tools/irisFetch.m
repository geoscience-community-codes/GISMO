classdef irisFetch
   % IRISFETCH allows seamless access to data stored within the IRIS-DMC via FDSN services
   %
   % irisFetch Methods:
   %
   % irisFetch waveform retrieval Methods:
   %    Traces - retrieve sac-equivalent waveforms with channel metadata
   %
   % irisFetch FDSN station webservice Methods:
   %    Channels - retrieve metadata as an array of channels
   %    Stations - retrieve metadata as an array of stations
   %    Networks - retrieve metadata as an array of networks
   %
   % irisFetch FDSN event webservice Methods:
   %    Events - retrieve events parameters (such as origins and magnitudes) from a catalog
   %
   % irisFetch miscelleneous Methods:
   %    Resp - retrive RESP formatted response data from the irisws-resp service
   %    version - display the current version number
   %    connectToJar - attempt to connect to the required IRIS-WS JAR file
   %    runExamples - displays and runs some sample queries to the web service.
   %
   %  irisFetch requires version 2.0 or greater of the IRIS Web Services Library java jar
   %  for more details, click on 'connectToJar' above.
   %
   %  For additional guidance, type help <method>, use irisFetch.runExamples, or check out
   %  the online manual http://www.iris.edu/dms/nodes/dmc/software/downloads/irisFetch.m/.
   %
   %see also JAVAADDPATH
   
   
   % Celso Reyes, Rich Karstens
   % IRIS-DMC
   % February 2014
   
   %{
 *******************************************************************************
 * Copyright (c) 2013 IRIS DMC supported by the National Science Foundation.
 *
 * This file is part of Iris Matlab Fetch (irisFetch).
 *
 * irisFetch is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * irisFetch is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * A copy of the GNU Lesser General Public License is available at
 * <http://www.gnu.org/licenses/>.
 ******************************************************************************
   %}
   
   properties (Constant = true)
      VERSION           = '2.0.6';  % irisFetch version number
      DATE_FORMATTER    = 'yyyy-mm-dd HH:MM:SS.FFF'; %default data format, in ms
      MIN_JAR_VERSION   = '2.0.4'; % minimum version of IRIS-WS jar required for compatibility
      
      VALID_QUALITIES   = {'D','R','Q','M','B'}; % list of Qualities accepted by Traces
      DEFAULT_QUALITY   = 'B'; % default Quality for Traces
      FETCHER_LIST      = {'Traces','Stations','Events','Resp'}; % list of functions that fetch
      forceDataAsDouble = true; %require that traces are returned as doubles regardless of original format
   end %constant properties
   
   properties (Constant = true, Hidden = true)
      MS_IN_DAY         = 86400000; % milliseconds in day
      BASE_DATENUM      = 719529; % Matlab startdate=0000-Jan-1 vs java's startdate=1970-Jan-1
      
      SURROGATE_JAR     = 'http://www.iris.edu/files/IRIS-WS/2/IRIS-WS-2.0-latest.jar';
      M2J_MAP           = containers.Map (...
         {'java.util.Date',...
         'java.lang.Double',...
         'java.lang.Long',...
         'java.lang.Integer',...
         'java.lang.String',...
         'boolean'},...
         {@(x) java.util.Date(((datenum(x)-irisFetch.BASE_DATENUM) * irisFetch.MS_IN_DAY) + .5), ...%@(x) irisFetch.mdate2jdate(x) ,...
         @(x) java.lang.Double(x),...
         @(x) java.lang.Long(x),...
         @(x) java.lang.Integer(x),...
         @(x) x,...
         @(x) x}...
         ); %details for MATLAB to JAVA conversions
      appName           = ['MATLAB:irisFetch/' irisFetch.VERSION]; %used as useragent of queries
      recursionAssert   = false; %check for recursions while parsing java into structs
   end %hidden constant properties
   
   methods(Static)
      function v = version()
         v = irisFetch.VERSION;
      end
      
      function ts = Traces(network, station, location, channel, startDate, endDate, varargin )
         %irisFetch.Traces retrieves sac-equivalent waveform with channel metadata
         %  tr = irisFetch.Traces(network, station, location, channel, startDate, endDate)
         %  will use channel and date criteria to retrieve one or more seismic traces,
         %  which are stored as structures containing typical SAC-equivalent metadata.
         %
         %  startDate and endDate must be formatted thusly:
         %      'YYYY-MM-DD hh:mm:ss' or 'YYYY-MM-DD hh:mm:ss.sss'
         %
         %  network, station, location, and channel all accept comma separated lists, as
         %  well as '*' and '?' wildcards.
         %
         %  tr = irisFetch.Traces(..., quality) allows you to specify the data's quality,
         %  such as 'B' (which stands for "best").  This SEED quality code defines how data overlaps
         %   are processed by the dataselect service.
         %
         %  tr = irisFetch.Traces(..., 'includePZ') will also retrieve poles and zeroes.
         %  These are the same poles/zeros as found from http://service.iris.edu/irisws/sacpz/1/
         %
         %  tr = irisFetch.Traces(..., 'verbose') provides additional debugging information
         %
         %  tr = irisFetch.Traces(..., usernameAndPassword ) allows authorized users to
         %  access restricted data. usernameAndPassword must be a cell containing the
         %  username and password.
         %     Sample:
         %       unamepwd = {'nobody@iris.edu', 'anonymous'}
         %
         %  tr = irisFetch.Traces(..., urlbase) will allow traces to be read from an
         %  alternate data center. url base is only the first part of the web address. For
         %  example, the IRIS datacenter would be 'http://service.iris.edu/'. These
         %  settings are "sticky", so that all calls for waveform data or station metadata
         %  will go to that datacenter until a new one is specified.
         %
         %  ABOUT THE RETURNED TRACE
         %    The returned trace(s) will be a 1xN array of structs. Each struct contains
         %    fields with information pertaining to that specific trace, such as channel
         %    information, start & end times, units, etc.
         %
         %    If the requested data does not exist, then an empty (1x0) trace struct will be
         %    returned. If the original data contains data gaps, then each continuous data
         %    segment will be returned as its own trace.
         %
         %  COMMON MANIPULATIONS:
         %
         %    See a text representation of the start date to millisecond accuracy, from a trace tr:
         %      datestr(tr.startTime, 'yyyy-mm-dd HH:MM:SS.FFF')
         %
         %    Scale the data, so that resulting values are in sensitivityUnits.
         %      tr.data = tr.data ./ tr.sensitivity;    % this example works only for single trace
         %
         %  EXAMPLES:
         %    Get 4 hours of data (timeseries + metdata) from a station:
         %      tr = irisFetch.Traces('IU','ANMO','10','BHZ','2010-02-27 06:30:00','2010-02-27 10:30:00')
         %
         %    Get 3 channels (via wildcards), including response, for a 4-hour time period:
         %      ts = irisFetch.Traces('IU','ANMO','10','BH?','2010-02-27 06:30:00','2010-02-27 10:30:00','includePZ')
         %
         %
         %    Get data from all channels from a comma-separated list of stations:
         %      ts = irisFetch.Traces('IU','ANMO,ANTO,YSS','00','*','2010-02-27 06:30:00','2010-02-27 10:30:00')
         %
         %  SEE ALSO datestr
         
         if ~exist('extensions.fetch.TraceData','class')
            irisFetch.connectToJar()
         end
         
         import edu.iris.dmc.*
         % import edu.iris.dmc.*
         
         % these variables are shared among all the nested functions
         getsacpz    = false;
         verbosity   = false;
         authorize   = false;
         quality     = irisFetch.DEFAULT_QUALITY;
         username    = '';
         userpwd     = '';
         newbase     = '';
         safeLocation = @(x) strrep(x,' ','-');
         
         extractAdditionalArguments(varargin);
         
         startDateStr   = irisFetch.makeDateStr(startDate);
         endDateStr     = irisFetch.makeDateStr(endDate);
         location       = safeLocation(location);
         
         tracedata      = edu.iris.dmc.extensions.fetch.TraceData();
         tracedata.setAppName(irisFetch.appName);
         tracedata.setVerbosity(verbosity);
         if ~isempty(newbase)
            if (verbosity)
                fprintf ('Using services at base: %s\n', newbase);
            end
            tracedata.setBASE_URL(newbase);
         end

         getTheTraces();
         
         return
         
         % ---------------------------------------------------------------
         % END TRACES: MAIN
         % ===============================================================
         
         
         function extractAdditionalArguments(argList)
            % extracts getsacpz, verbosity, authorize, quality, username, and userpwd
            % Parameters are handled "intelligently" so that [paramname, paramval] pairs
            % aren't necessry
            
            for n=1:numel(argList)
               param = argList{n};
               switch class(param)
                  case 'cell'
                     assert(numel(param)==2 && all(cellfun(@ischar, param)),...
                        'A cell parameter is assumed to contain credentials. eg. {''nobody@iris.edu'',''anonymous''}.');
                     [username, userpwd] = deal(param{:});
                     authorize         = true;
                  case 'char'
                     switch upper(param)
                        case irisFetch.VALID_QUALITIES
                           quality     = param;
                        case {'INCLUDEPZ'}
                           getsacpz    = true;
                        case {'VERBOSE'}
                           verbosity   = true;
                        otherwise
                           if length(param)>7 && strcmpi(param(1:7),'http://')
                              % set the bases
                              newbase = param;
                           else
                           error('IRISFETCH:Trace:unrecognizedParameter',...
                              'The text you included as an optional parameter did not parse to either a qualitytype (D,R,Q,M,B) or ''INCLUDEPZ'' or ''VERBOSE'' or a service base URL');
                           end
                     end
                     %case 'logical' DEPRECATED
                     %   verbosity         = param; % old usage, deprecated.
                  otherwise
                     error('IRISFETCH:Trace:unrecognizedParameter',...
                        'The optional parameter wasn''t recognized. %s', class(param));
               end
            end
            
            if verbosity
               disp({'spz:',getsacpz,'vb:',verbosity,'auth:',authorize,'qual:',quality,'un&pw:',username,userpwd});
            end
            
         end % extractAdditionalArguments
         
         function getTheTraces()
            traces=[];
            try
               if authorize
                  if verbosity
                     fprintf('traces = tracedata.fetchTraces("%s", "%s", "%s", "%s", "%s", "%s", ''%s'', %d, "%s", "%s")\n',...
                        network, station, location, channel, startDateStr, endDateStr, quality, getsacpz, username, userpwd);%char(userpwd - userpwd + 42));
                  end
                  traces = tracedata.fetchTraces(network, station, location, channel, ...
                     startDateStr, endDateStr, quality, getsacpz, username, userpwd);  %db removed (;)
               else
                  if verbosity
                     fprintf('traces = tracedata.fetchTraces("%s", "%s", "%s", "%s", "%s", "%s", ''%s'', %d)\n',...
                        network, station, location, channel, startDateStr, endDateStr, quality, getsacpz);
                  end
                  traces = tracedata.fetchTraces(network, station, location, channel, ...
                     startDateStr, endDateStr, quality, getsacpz); %db removed (;)
               end
               if verbosity
                  fprintf('tracedata.fetchTraces successfully completed, resulting in %d traces before converting\n', numel(traces)); %db
               end
            catch je
               % Debug messages:
               %warning('An [%s] exception occurred in irisFetch.getTheTraces() but was caught\n full text follows:\nmessage:\n%s\n\n', je.identifier,je.message) %db
               %disp(je.cause); %db
               %disp(je.stack); %db
               
               switch je.identifier
                  case 'MATLAB:Java:GenericException'
                     if any(strfind(je.message,'URLNotFoundException'));
                        error('IRISFETCH:Trace:URLNotFoundException',...
                           'Trace found no requested data and returned the following error:\n%s',...
                           je.message);
                     end
                     if any(strfind(je.message,'java.io.IOException: edu.iris.dmc.service.UnauthorizedAccessException'));
                        error('IRISFETCH:Trace:UnauthorizedAccessException',...
                           'Invalid Username and Password combination\n');
                     end
                     if any(strfind(je.message,'NoDataFoundException'));
                        if verbosity
                           warning('IRISFETCH:Trace:URLNotFoundException',...
                           'Trace found no requested data and returned the following error:\n%s',...
                           je.message);
                        end
                     end
                  otherwise
                     fprintf('Exception occured in IRIS Web Services Library: %s\n', je.message);
                     rethrow(je)
               end
            end
            
            ts = irisFetch.convertTraces(traces);
            clear traces
            
         end %function getTheTraces
      end % Traces
      
      function [channelStructure, urlParams] = Channels(detailLevel, varargin)
         %irisFetch.Channels retrieves station metadata from IRIS-DMC as an array of channels
         %  s = irisFetch.Channels(DETAIL,NETWORK,STATION,LOCATION,CHANNEL) retrieves
         %  station metadata from the IRIS-DMC into an array of channels.  DETAIL is one of 
         %  'CHANNEL', or 'RESPONSE' and should be explicitly declared. DETAIL defaults to 'CHANNEL'
         %  Network, station, location, and channel parameters are passed directly to the
         %  java library, so both comma-separated  lists and wildcards (? and *) are accepted.  
         %  
         %  All five parameters are required for all queries, but may be wildcarded by
         %  using '' for their values.
         %
         %  [s, myParams] = irisFetch.Channels( ... ) also returns the URL parameters that
         %  were used to make the query.
         %
         %  irisFetch.Channels(..., 'BASEURL',alternateURL) specifies an alternate base URL
         %  to query. By default queries go to: http://service.iris.edu/fdsnws/station/1/
         %
         %  s = irisFetch.Channels( ... , paramName, value [, ...]]) allows any number of
         %  parameter-value pairs to be included in the selection criteria.  Valid
         %  parameter names are listed in help for irisFetch.Networks
         %
         %  Example: to retrieve channel-level BHZ metadata from any station named ANMO:
         %      s = irisFetch.Channels('channel','*','ANMO','*','BHZ')
         %
         %  Note: This function effectively deprecates irisFetch.flattenToChannel
         %
         %See also Networks, Stations
         
         if isempty(detailLevel)
            detailLevel = 'CHANNEL';
         end         
         assert(ismember(upper(detailLevel),{'CHANNEL','RESPONSE'}),...
            'To retrieve channels, the detailLevel must be either ''CHANNEL'' or ''RESPONSE''');
         [channelStructure, urlParams] = irisFetch.Networks(detailLevel, varargin{:});
         if ~isempty(channelStructure)
            channelStructure = irisFetch.flattenToChannel(channelStructure);
         end
      end
      
      function [stationStructure, urlParams] = Stations(detailLevel, varargin)
         %irisFetch.Stations retrieves station metadata from IRIS-DMC as an array of stations
         %  s = irisFetch.Stations(DETAIL,NETWORK,STATION,LOCATION,CHANNEL) retrieves
         %  station metadata from the IRIS-DMC into an array of stations.  DETAIL is one
         %  of 'STATION','CHANNEL', or  'RESPONSE' and should be explicitly declared.
         %  DETAIL defaults to 'STATION'
         %
         %  Network, station, location, and channel parameters are passed directly to the
         %  java library, so both comma-separated lists and wildcards (? and *) are accepted.
         %  
         %  All five parameters are required for all queries, but may be wildcarded by
         %  using '' for their values.
         %
         %  [s, myParams] = irisFetch.Stations( ... ) also returns the URL parameters that
         %  were used to make the query.
         %
         %  irisFetch.Stations(..., 'BASEURL',alternateURL) specifies an alternate base URL
         %  to query. By default queries go to: http://service.iris.edu/fdsnws/station/1/
         %
         %  s = irisFetch.Stations( ... , paramName, value [, ...]]) allows any number of
         %  parameter-value pairs to be included in the selection criteria.  Valid
         %  parameter names are listed in help for irisFetch.Networks
         %
         %  Example: to retrieve channel-level metadata, stored in an array of stations:
         %      s = irisFetch.Stations('channel','IU','A*','*','BHZ')
         %
         %  Note: This function effectively deprecates the irisFetch.flattenToStation
         %
         %See also Networks, Channels
         
         if isempty(detailLevel)
            detailLevel = 'STATION';
         end         
         assert(ismember(upper(detailLevel),{'STATION','CHANNEL','RESPONSE'}),...
            'To retrieve stations, the detailLevel must be either ''STATION'', ''CHANNEL'', or ''RESPONSE''');
         [stationStructure, urlParams] = irisFetch.Networks(detailLevel,varargin{:});
         if ~isempty(stationStructure)
            stationStructure = irisFetch.flattenToStation(stationStructure);
         end
      end
      
      function [networkStructure, urlParams] = Networks(detailLevel, network, station, location, channel, varargin)
         %irisFetch.Stations retrieves station metadata from IRIS-DMC as an array of networks
         %  s = irisFetch.Networks(DETAIL,NETWORK,STATION,LOCATION,CHANNEL), retrieves
         %  station metadata into an array of networks. These parameters are required for
         %  all queries, but may be wildcarded by using '' for their values. Network,
         %  station, location, and channel parameters are passed directly to the java
         %  library, so both comma-separated lists and wildcards (? and *) are accepted.
         %  Detail is one of 'NETWORK','STATION','CHANNEL', or 'RESPONSE' and should be  
         %  explicitly declared. Defaults to 'NETWORK' 
         %
         %  [s, myParams] = irisFetch.Networks( ... ) also returns the URL parameters that
         %  were used to make the query.
         %
         %  irisFetch.Networks(..., 'BASEURL',alternateURL) specifies an alternate base URL
         %  to query. By default queries go to: http://service.iris.edu/fdsnws/station/1/
         %
         %  s = irisFetch.Networks( ... , paramName, value [, ...]]) allows any number of
         %  parameter-value pairs to be included in the selection criteria.  See the list
         %  below.
         %
         %  Valid parameters are listed below.  For detailed descriptions of their effect
         %  and use, consult the station webservice webpage, available at:
         %     http://service.iris.edu/fdsnws/station/1/
         %
         %  PARAMETER LIST (for IRIS-WS-2.0.0.jar)
         %    The following take time values, of the format 'yyyy-mm-dd HH:MM:SS'
         %      'StartTime', 'EndTime', 'StartBefore', 'EndBefore'
         %      'StartAfter', 'EndAfter' 'UpdatedAfter'
         %
         %    The following take values in degrees and work together to define a search box
         %      'MinimumLatitude', 'MaximumLatitude', 'MinimumLongitude','MaximumLongitude'
         %
         %    These params take values in degrees to define a search disk / annular region
         %      'Latitude', 'Longitude', 'MinimumRadius','MaximumRadius'
         %
         %    Other params, that accept true or false  (no quotes)
         %    'IncludeAvailability','MatchTimeSeries', 'IncludeRestricted'
         %
         %  CONVENIENCE PARAMETERS
         %    'boxcoordinates'    : [minLat, maxLat, minLon, maxLon]
         %                           % use NaN as a wildcard
         %    'radialcoordinates' : 1x4 double :
         %                           [Lat, Lon, MaxRadius, MinRadius]
         %                           % MinRadius is optional
         %
         %  To retrieve similar information, but organize as an array of either channels
         %  or stations, use irisFetch.Channels or irisFetch.Stations respectively.
         %
         %SEE ALSO Channels, Stations
         import edu.iris.dmc.*
         outputLevel  = '';
         service      = []; % will be a java service object
         crit         = []; % will be a java criteria object
         j_networks   = []; % will be the returned java networks
         
         %if ~exist('edu.iris.dmc.criteria.StationCriteria','class')
         if ~exist('criteria.StationCriteria','class')
            irisFetch.connectToJar()
         end
                  
         if isempty(detailLevel)
            detailLevel = 'NETWORK';
         end         
         
         verifyArguments(nargin);
         setOutputLevel();
         connectToStationService();
         setCriteria();
         fetchTheStations();
         networkStructure=irisFetch.parser_for_IRIS_WS_2_0_0(j_networks);
         
         if nargout == 2
            urlParams = crit.toUrlParams;
         end
         return
         
         % -------------------------------------------------------------
         % END STATIONS: MAIN
         % =============================================================
         
         function verifyArguments(nArgs)
            if nArgs==1 && strcmpi(detailLevel,'help')
               disp('HELP request recognized, but not implemented');
               return
            elseif nArgs < 5
               error('not enough arguments.%d',nArgs);
            end
         end %verifyArguments
         
         function setOutputLevel()
            try
               outputLevel = edu.iris.dmc.criteria.OutputLevel.(upper(detailLevel));
               % outputLevel = edu.iris.dmc.criteria.OutputLevel.(upper(detailLevel));
            catch je
               switch je.identifier
                  case 'MATLAB:undefinedVarOrClass'
                     error('IRISFETCH:NoIrisWSJarInstalled',...
                        ['The necessary IRIS-WS java library was not recognized or found. ',...
                        'Please ensure it is on your javaclasspath']);
                  case 'MATLAB:subscripting:classHasNoPropertyOrMethod'
                     error('IRISFETCH:invalidOutputLevel',...
                        'The selected outputLevel [''%s''] was not recognized.',...
                        upper(detailLevel));
                  otherwise
                     rethrow(je);
               end
            end
         end % setOutputLevel
         
         function connectToStationService()
            serviceManager = edu.iris.dmc.service.ServiceUtil.getInstance();
            serviceManager.setAppName(['MATLAB:irisFetch/' irisFetch.version()])
            setBaseUrlFromParameterList();
            removeParameter('BASEURL');
            return
            
            % - - - - - - - - - - - - - - -
            function setBaseUrlFromParameterList()
               baseUrl = getParameter('BASEURL');
               if ~isempty(baseUrl)
                  service = serviceManager.getStationService(baseUrl);
               else
                  service = serviceManager.getStationService();
               end % setBaseUrlFromParameterList
            end
            
         end %connectToStationService()
         
         function removeParameter(s)
            [UNUSED_VARIABLE, idx] = getParameter(s); %#ok<ASGLU>
            varargin(idx * 2 -1 : idx* 2) = [];
         end
         
         function [p, i] = getParameter(s)
            i = find(strcmpi(parameterNames(),s),1,'first');
            p = parameterValues();
            p = p(i);
         end
         
         function pn = parameterNames()
            pn = varargin(1:2:end);
         end
         
         function pv = parameterValues()
            pv = varargin(2:2:end);
         end
         
         function setCriteria()
            crit = edu.iris.dmc.criteria.StationCriteria;
            %crit = edu.iris.dmc.criteria.StationCriteria;
            
            %----------------------------------------------------------
            % Deal with the Station/Network/Channel/Location parameters
            % These are treated separately, as they're "add" & not "set"
            % Each may handle multiple strings (as a cell array)
            %----------------------------------------------------------
            
            crit = irisFetch.addCriteria(crit, network, 'addNetwork');
            crit = irisFetch.addCriteria(crit, station, 'addStation');
            crit = irisFetch.addCriteria(crit, location,'addLocation');
            crit = irisFetch.addCriteria(crit, channel, 'addChannel');
            crit = irisFetch.setCriteria(crit, varargin);
         end %setCriteria
         
         function fetchTheStations()
            try
               j_networks = service.fetch(crit, outputLevel);
            catch je
               if strfind(je.message,'ServiceNotSupportedException')
                  error('IRISFETCH:ServiceNotSupportedByLibrary',...
                     'The IRIS-WS java library version doesn''t support the requested station service version');
               elseif strfind(je.message,'NoDataFoundException')
                  warning('IRISFETCH:NoDataFoundException','No data was found that matched your criteria');
                  j_networks = [];
               else
                  rethrow(je)
               end
            end %catch
         end %fetchTheStations
         
      end %Networks
      
      function [events, urlParams] = Events(varargin)
         %irisFetch.Events retrieves event data from the IRIS-DMC
         %  ev = irisFetch.Events(param, value [, ...]) retrieves event data from the
         %  IRIS-DMC database as a matlab structure.  An arbitrary number of
         %  parameter-value pairs may be specified in order to narrow down the search
         %  results.
         %
         %  [ev, myParams] = irisFetch.Events( ... ) also returns the URL parameters that
         %  were used to make the query.
         %
         %  irisFetch.Events(..., 'BASEURL',alternateURL) specifies an alternate base URL
         %  to query. By default queries go to: http://service.iris.edu/fdsnws/event/1/
         %
         %  Usable parameters are listed below.  For detailed descriptions of their effect
         %  and use, consult the webservice webpage for events, available at:
         %
         %  http://service.iris.edu/fdsnws/event/1/
         %
         %  Examples:
         %
         %  Retrieve event parameters regarding earthquakes of a specific size and location:
         %      ev = irisFetch.Events('MinimumMagnitude',6.0,...
         %          'minimumLatitude',45,'maximumLatitude', 60,...
         %          'minimumLongitude', -150,'maximumLongitude', -90)
         %
         %PARAMETER LIST (for IRIS-WS-2.0.0.jar)
         % contributor, endTime, eventId, fetchLimit, latitude, longitude, magnitudeType,
         % maximumDepth, maximumLatitude, maximumLongitude, maximumMagnitude,
         % minimumDepth, minimumLatitude, minimumLongitude, minimumMagnitude,
         % minimumRadius, maximumRadius, offset, startTime updatedAfter
         %
         %CONVENIENCE PARAMETERS
         %   'boxcoordinates'    : [minLat, maxLat, minLon, maxLon]   % use NaN as a wildcard
         %   'radialcoordinates' : [Lat, Lon, MaxRadius, MinRadius]   % MinRadius is optional
         %
         %NOTE: Any parameter-value pair that is not listed here will be passed along to
         %      the Event Service. this is to accomodate other datacenters that may have
         %      specialized request parameters.
         
         import edu.iris.dmc.*
         % import edu.iris.dmc.*
         
         %if ~exist('edu.iris.dmc.criteria.EventCriteria','class')
         if ~exist('criteria.EventCriteria','class')
            irisFetch.connectToJar()
         end
         
         %serviceManager = ws.service.ServiceUtil.getInstance();
         serviceManager = edu.iris.dmc.service.ServiceUtil.getInstance();
         serviceManager.setAppName(['MATLAB:irisFetch/' irisFetch.version()]);
         
         indexOffsetOfBASEURL=find(strcmpi(varargin(1:2:end),'BASEURL'),1,'first') * 2;
         
         if ~isempty(indexOffsetOfBASEURL)
            baseURL = varargin{indexOffsetOfBASEURL};
         end
         
         if exist('baseURL','var')
            varargin(indexOffsetOfBASEURL-1:indexOffsetOfBASEURL) = [];
            service = serviceManager.getEventService(baseURL);
         else
            service = serviceManager.getEventService();
         end
         
         %crit = ws.criteria.EventCriteria;
         crit = criteria.EventCriteria;
         crit = irisFetch.setCriteria(crit, varargin);
         if nargout == 2
            urlParams = crit.toUrlParams;
         end
         disp('fetching...')
         try
            j_events = service.fetch(crit);
         catch er
            if any(strfind(er.message,'NoDataFoundException')) || any(strfind(er.message,'No Content'))
               warning('IRISFETCH:NoDataFoundException','No data was found that matched your criteria');
               events=[];
               return
            end
            rethrow(er);
         end
         fprintf('\n\n%d events found *************\n\n',j_events.size);
         disp('parsing into MATLAB structures')
         events=irisFetch.parser_for_IRIS_WS_2_0_0(j_events);
         % v2.0 uses Preferred, while original code uses "Primary"
      end
            
      function connectToJar(isSilent)
         %irisFetch.connectToJar connects to the jar for this MATLAB session
         %  irisFetch.connectToJar() searches the javaclasspath for the
         %  IRIS-WS jar file. If it does not exist, then it will try to access the latest
         %  jar over the internet. If it cannot connect, it will error.
         %
         %  irisFetch requires version 2.0.2 or greater of the IRIS Web Services Library java jar,
         %  available from:
         %
         %  http://www.iris.edu/files/IRIS-WS/2/
         %
         %  This jar file must be added to your MATLAB path, which may be done
         %  in a variety of ways.  One common way is to include a javaaddpath
         %  statement in the startup.m file.  For more details, consult MATLAB's
         %  documentation for 'Bringing Java Classes and Methods into MATLAB
         %  Workspace'.
         %
         % SEE ALSO javaaddpath
         
         assert(usejava('jvm'),'IRISFETCH:jvmNotRunning','irisFetch requires Java to run.');
         isSilent = nargin>0 && strcmpi(isSilent,'silent');
         
         if exist('edu.iris.dmc.extensions.fetch.TraceData','class');
            return
         end
         
         if ~isSilent
            disp('please add the latest IRIS-WS.jar file to your javaclasspath.');
            fprintf('Available here: %s\n',irisFetch.SURROGATE_JAR);
            disp('ex.  javaaddpath(''/usr/local/somewhere/IRIS-WS.jar'');');
         end
         
         javaaddpath(irisFetch.SURROGATE_JAR);
         
         if ~exist('edu.iris.dmc.extensions.fetch.TraceData','class');
            error('irisFetch:noDefaultJar',...
               'Unable to access the default jar.  Please download and add the latest IRIS-WS-JAR to your javaclasspath.');
         end
      end
            
      function [respstructures, urlparams] = Resp(network, station, location, channel, starttime, endtime)
         % retrieve the RESP information into a character string.
         % net, sta, loc, and cha are all required.
         % channels and locations may be wildcarded using either ? or *
         % starttime and endtime options may be ignored by using [] instead of a time.
         
         import edu.iris.dmc.*
         
         %crit = edu.iris.dmc.criteria.RespCriteria();
         crit = criteria.RespCriteria();
         crit.setNetwork(network);
         crit.setStation(station);
         crit.setLocation(location);
         crit.setChannel(channel);
         if ~isempty(starttime)
            crit.setStartTime(irisFetch.mdate2jdate(starttime));
         end
         if ~isempty(endtime)
            crit.setEndTime(irisFetch.mdate2jdate(endtime));
         end
         urlparams = char(crit.toUrlParams());
         
         serviceManager = edu.iris.dmc.service.ServiceUtil.getInstance();
         baseUrl = 'http://service.iris.edu/irisws/resp/1/';
         serviceManager.setAppName(['MATLAB:irisFetch/' irisFetch.version()]);
         service = serviceManager.getRespService(baseUrl);
         respstructures= char(service.fetch(crit));
      end
      
      function runExamples()
         delay=1; % seconds
         codeToExecute={
            '% Retrieve 1 hr of all ''HZ'' channels from all locations at station ANMO for net IU'
            'traces = irisFetch.Traces(''IU'',''ANMO'',''*'',''?HZ'',''2010-02-27 06:30:00'',''2010-02-27 07:30:00'')'
            '% Notice that multiple traces were retrieved, look at the first trace.'
            'tr = traces(1)'
            '% -------- plot the data from the first trace, and then label the plot ------'
            'sampletimes=linspace(tr.startTime,tr.endTime,tr.sampleCount); %calculate the time of each sample'
            'whos(''sampletimes'')'
            'plot(sampletimes,tr.data);'
            'legendDetails = sprintf(''%s-%s-%s'', tr.network, tr.station, tr.location, tr.channel)'
            'legend(legendDetails);'
            'title(''Simple plot'');'
            'datetick;'
            ' '
            '% next, get some station data (same data, at different levels of detail'
            'n = irisFetch.Networks(''Response'',''IU'',''ANMO'','''',''BHZ'',''baseurl'',''http://service.iris.edu/fdsnws/station/1/'')';
            's = irisFetch.Stations(''Response'',''IU'',''ANMO'','''',''BHZ'')';
            'c = irisFetch.Channels(''Response'',''IU'',''ANMO'','''',''BHZ'')';
            ' '
            '% retrieve station data using other search parameters'
            'arcticNetworkList = irisFetch.Networks(''Station'','''','''','''','''',''minimumlatitude'',66.3)';
            'netNames = {arcticNetworkList.NetworkCode}'
            ' '
            '% retrieve event data'
            ' ev = irisFetch.Events(''minimummagnitude'',8.0)'
            ' ev(1)'
            ' ev = irisFetch.Events(''starttime'',''2010-02-27'',''endtime'',''2010-02-28 12:00:00'',''catalog'',''ISC'',''includeallorigins'',true,''includeallmagnitudes'',true)'
            ' '
            '% retrieve the RESP formatted response for a station'
            'irisFetch.Resp(''IU'',''ANMO'',''00'',''BHZ'',now,now)'
            };
         for n=1:numel(codeToExecute)
            disp(codeToExecute{n});
            eval(codeToExecute{n});
            pause(delay);
         end
         clear traces tr n s c ev
         
      end %fn runExamples
   end % static methods
   
   methods(Static, Hidden=true)
      
      function channelList = flattenToChannel(networkTree)
         %irisFetch.flattenToChannel flattens the structure returned by irisFetch.Networks
         %  flatStruct = irisFetch.flattenToChannel(networkTree) takes the hierarchy
         %  returned by irisFetch.Networks, and returns a 1xN array of channels  (channel
         %  epochs, technically).
         % 
         %  flatStruct is an array containing ALL channel epochs.
                           
         assert(isa(networkTree,'struct'),'Cannot Flatten a non-structure');
         
         %eliminate stations that have no channels
         for n=1:numel(networkTree)
            hasNoChannel = arrayfun(@(x) isempty(x.Channels),networkTree(n).Stations);
            networkTree(n).Stations(hasNoChannel) = []; % networkTree(n).Stations(~hasNoChannel);
         end         
         
         %eliminate networks that have no stations
         networksWithoutStations = arrayfun(@(x) isempty(x.Stations),networkTree);         
         networkTree(networksWithoutStations) = [];
         
         if isempty(networkTree); 
            warning('IRISFETCH:flattenToChannel:noValidChannels','No channels found, returning an empty array');
            return
         end
         
         for n=1:numel(networkTree)
            nc    = networkTree(n).NetworkCode;
            nd    = networkTree(n).Description;
            [networkTree(n).Stations.NetworkCode]        = deal(nc);
            [networkTree(n).Stations.NetworkDescription] = deal(nd);
            for m = 1 : numel(networkTree(n).Stations)
               sc = networkTree(n).Stations(m).StationCode;
               sd = networkTree(n).Stations(m).Description;
               sn = networkTree(n).Stations(m).Site;
               [networkTree(n).Stations(m).Channels.NetworkCode]        = deal(nc);
               [networkTree(n).Stations(m).Channels.NetworkDescription] = deal(nd);
               [networkTree(n).Stations(m).Channels.StationCode]        = deal(sc);
               [networkTree(n).Stations(m).Channels.StationDescription] = deal(sd);
               [networkTree(n).Stations(m).Channels.Site] = deal(sn);
               % write the long StationName again to the main level.
               [networkTree(n).Stations(m).Channels.StationName] = deal(sn.Name);
            end
         end
         tmp = [networkTree.Stations];
         channelList=[tmp.Channels];    
         
         clear tmp
         % now, reorder to make it visually coherent.
         descriptorstuff={'NetworkCode';'StationCode';'LocationCode';'ChannelCode';'NetworkDescription';'StationName';'Site'};
         positionalstuff={'Latitude';'Longitude';'Elevation';'Depth';'Azimuth';'Dip'};
         otherstuff={'SampleRate';'SampleRateRatio';'StartDate';'EndDate'};
         fieldsattop=[descriptorstuff; positionalstuff; otherstuff];
         
         fn = fieldnames(channelList);
         fieldsattop = fieldsattop(ismember(fieldsattop,fn)); %ensure fields exist
         
         for n=1:numel(fieldsattop);
            fn(strcmp(fn,fieldsattop(n))) = [];
         end
         neworder = [fieldsattop; fn];
         channelList = orderfields(channelList, neworder);
      end
      
      function stationList = flattenToStation(networkTree)
         %irisFetch.flattenToStation flattens the structure returned by irisFetch.Stations
         %
         %USAGE
         %  flatStruct = irisFetch.flattenToStation(networkTree)
         %
         %This takes the hierarchy returned by irisFetch.Stations, and
         %returns a 1xN array of stations (station epochs, technically).
         
         assert(isa(networkTree,'struct'),'Cannot Flatten a non-structure');
                  
         emptyNetworks = arrayfun(@(x) isempty(x.Stations),networkTree);
         
         for n=1:numel(networkTree)
            nc    = networkTree(n).NetworkCode;
            nd    = networkTree(n).Description;
            [networkTree(n).Stations.NetworkCode]        = deal(nc);
            [networkTree(n).Stations.NetworkDescription] = deal(nd);
         end
         
         stationList = [networkTree(~emptyNetworks).Stations];
         
         for m=1:numel(stationList)
               stationList(m).StationName = stationList(m).Site.Name;
         end
         
         % now, reorder to make it visually coherent.
         descriptorstuff={'NetworkCode';'StationCode';'NetworkDescription';'StationName';'Site'};
         positionalstuff={'Latitude';'Longitude';'Elevation'};
         otherstuff={'StartDate';'EndDate'};
         fieldsattop=[descriptorstuff; positionalstuff; otherstuff];
         if ~isstruct(stationList)
            warning('IRISFETCH:flattenToStation:noValidStations','No stations found, returning an empty array');
            return
         end
         fn = fieldnames(stationList);
         fieldsattop = fieldsattop(ismember(fieldsattop,fn)); %ensure fields exist
         
         for n=1:numel(fieldsattop);
            fn(strcmp(fn,fieldsattop(n))) = [];
         end
         neworder = [fieldsattop; fn];
         stationList = orderfields(stationList, neworder);
      end
     
      function [js, je] = testResp(starttime, endtime)
         n=now;
         testThis('IU','ANMO','00','BHZ',[],[]);
         testThis('IU','ANMO','00','*',[],[]);
         testThis('IU','ANMO','*','BHZ',[],[]);
         testThis('IU','ANMO','00','BHZ',[],now-1);
         testThis('IU','ANMO','00','BHZ',n-600,[]);
         testThis('IU','ANMO','00','BHZ',n,n-1);
         testThis('IU','ANMO','?0','BHZ',n,n-1);
         testThis('IU','ANMO','00','B?Z',n,n-1);
         testThis('IU','ANMO','00','BHZ','9/20/2012','9/20/2012 03:00:00');
         %testThis('IU','*','00','BHZ',[],[]); %should fail
         %testThis('*','ANMO','00','BHZ',[],[]); % should fail
         if exist('starttime','var') && ~isempty(starttime)
            js = showTimeInDetail(starttime);
         end
         disp(' ');
         if exist('endtime','var') && ~isempty(endtime)
            je = showTimeInDetail(endtime);
         end
         
         function testThis(varargin)
            try
               [r, url] = irisFetch.Resp(varargin{:});
               whos r
               disp(['url: ', url]);
               
               parampairs={
                  'network'   ,varargin{1}, 'station'   ,varargin{2}, 'location'  ,varargin{3}, 'channel'   ,varargin{4}
                  };
               disp(paramPairs)
               
               if ~isempty(varargin{5})
                  st = datestr(varargin{5},31);
                  st(11)='T';
                  parampairs = [parampairs, {'starttime',st}];
               end
               
               if ~isempty(varargin{6})
                  ed = datestr(varargin{6},31);
                  ed(11)='T';
                  parampairs = [parampairs, {'endtime',ed}];
               end
               
               [s,code]=urlread('http://service.iris.edu/irisws/resp/1/query','get', parampairs); %#ok<NASGU>
               
               assert(strcmp(r,s));
            catch myerror
               warning('RESPTEST:failure',myerror.identifier);
            end
         end
         
         function javadateTime = showTimeInDetail(t)
            dv          = datevec(t);
            dv(6)       = ceil(dv(6) * 1000) / 1000;
            t           = datenum(dv);
            s           = dv(6);
            % t must be either a date number or a string.
            javadateTime      = irisFetch.mdate2jdate(t);
            matlabTimeString  = datestr(t,irisFetch.DATE_FORMATTER);
            %crit          = edu.iris.dmc.criteria.RespCriteria();
            crit          = criteria.RespCriteria();
            crit.setEndTime(javadateTime);
            reconvertedMatlabTime = ...
               datestr(irisFetch.jdate2mdate(javadateTime),irisFetch.DATE_FORMATTER);
            %urlString         = char(criteria.toUrlParams().get(0));
            urlString         = crit.toUrlParams().get(0).toCharArray()';
            if ~(all(reconvertedMatlabTime == matlabTimeString));
               disp(s-fix(s));
               if datenum(reconvertedMatlabTime) > datenum(t)
                  fprintf('^ ');
               else
                  fprintf('v ');
               end
               fprintf('InputTime: %s  ; jDateTime: %s ; millis: %d\nReConvert: %s\nURL: %s\n',...
                  matlabTimeString, ...
                  javadateTime.toGMTString.toCharArray()', ...
                  rem(javadateTime.getTime(),1000),...
                  reconvertedMatlabTime,...
                  urlString);
            end
         end %fn showTimeInDetail
      end %fn testResp
   end %static hidden methods
  
   
   methods(Static, Access=protected)      
      function myDateStr = makeDateStr(dateInput)
         myDateStr = datestr(dateInput, irisFetch.DATE_FORMATTER);
      end
      
      function d = jArrayList2complex(jArrayList)
         % for use on ArrayList objects containing things with getReal() and getImaginary()
         %  edu.iris.dmc.sacpz.model.Pole
         %  edu.iris.dmc.sacpz.model.Zero
         %  edu.iris.dmc.station.model.ComplexNumber
         
         if jArrayList.size()<1
            assert(0==1,'Never should reach this');
            d      = zeros(0,1); % optimized
         else
            jArray = jArrayList.toArray;
            dr     = zeros(numel(jArray),1);
            di     = zeros(numel(jArray),1);
            
            for n = 1 : jArrayList.size()%:-1: 1
               dr(n,1) = jArray(n).getReal().doubleValue;
               di(n,1) = jArray(n).getImaginary().doubleValue;
            end
            d      = complex(dr,di);
         end
         
      end
      
      function mts = convertTraces(traces)
         %irisFetch.convertTraces converts traces from java to a matlab structure
         %   mts = convertTraces(traces) where TRACES a java trace class. If the input
         %   traces are empty, then a 1x0 structure is returned.
         blankSacPZ = struct('units','','constant',[],'poles',[],'zeros',[]);
         
         blankTrace = struct('network','','station','','location',''...
            ,'channel','','quality','',...
            'latitude',0,'longitude',0,'elevation',0,'depth',0,...
            'azimuth',0,'dip',0,...
            'sensitivity',0,'sensitivityFrequency',0,...
            'instrument','','sensitivityUnits','UNK',...
            'data',[],'sampleCount',0,'sampleRate',nan,...
            'startTime',0,'endTime',0,'sacpz',blankSacPZ);
         mts=blankTrace;
         if isempty(traces)
            disp('... since traces is empty, creating an empty structure')
            mts(1) = []; % keep the structure, but force it to be 1x0 trace
         end
         for i = 1:length(traces)
            mt=blankTrace;
            mt.network  = char(traces(i).getNetwork());
            mt.station  = char(traces(i).getStation());
            mt.location = char(traces(i).getLocation());
            mt.channel  = char(traces(i).getChannel());
            
            mt.quality  = char(traces(i).getQuality());
            
            mt.latitude  = traces(i).getLatitude();
            mt.longitude = traces(i).getLongitude();
            mt.elevation = traces(i).getElevation();
            mt.depth     = traces(i).getDepth();
            mt.azimuth   = traces(i).getAzimuth();
            mt.dip       = traces(i).getDip();
            
            mt.sensitivity = traces(i).getSensitivity();
            mt.sensitivityFrequency = traces(i).getSensitivityFrequency();
            
            mt.instrument  = char(traces(i).getInstrument());
            mt.sensitivityUnits = char(traces(i).getSensitivityUnits());
            dataType = char(traces(i).getDataType);
            switch dataType
               case {'INTEGER','INT24'}
                  mt.data        = traces(i).getAsInt();
               case {'DOUBLE'}
                  mt.data        = traces(i).getAsDouble();
               case {'FLOAT'}
                  mt.data        = traces(i).getAsFloat();
               case {'SHORT'}
                  mt.data        = traces(i).getAsShort();
               otherwise
                  % mt.data      = traces(i).getData(); %returns an ArrayList
                  mt.data        = traces(i).getAsDouble();
                  warning('IRISFETCH:convertTraces:noDataTypeSpecified',...
                     'No dataType was specified by the retrieved trace. returning as Double (which may be incorrect)');
            end
            if irisFetch.forceDataAsDouble
               mt.data = double(mt.data);
            end
            mt.sampleCount = traces(i).getSampleCount();
            mt.sampleRate  = traces(i).getSampleRate();
            
            startDateString = char(traces(i).getStartTime().toString());
            endDateString  = char(traces(i).getEndTime().toString());
            
            mt.startTime   = datenum(startDateString, irisFetch.DATE_FORMATTER);
            mt.endTime     = datenum(endDateString, irisFetch.DATE_FORMATTER);
            
            try
               jsacpz = traces(i).getSacpz();
            catch er
               warning('An [%s] exception occurred in irisFetch.convertTraces() but was caught\n full text follows', er.identifier) %db
               disp(er);
               if strcmp(er.identifier,'MATLAB:noSuchMethodOrField')
                  warning('IRISFETCH:convertTraces:noGetSacPZmethod',...
                     'probably using older verision of the ws-library. please retrieve the latest version');
                  jsacpz = [];
               else
                  rethrow(er)
               end
            end
            if ~isempty(jsacpz)
               sacpz.units       = char(traces(i).getSacpz().getInputUnit());
               sacpz.constant    = traces(i).getSacpz().getConstant();
               if ( not(traces(i).getSacpz().getPoles().isEmpty()) )
                   sacpz.poles   = irisFetch.jArrayList2complex(traces(i).getSacpz().getPoles());
               else
                   sacpz.poles   = [];
               end
               if ( not(traces(i).getSacpz().getZeros().isEmpty()) )
                   sacpz.zeros   = irisFetch.jArrayList2complex(traces(i).getSacpz().getZeros());
               else
                   sacpz.zeros   = [];
               end
               mt.sacpz          = sacpz;
            end
            mts(i) = mt;
         end
      end
      
      
      %----------------------------------------------------------------
      % DATE conversion routines
      %
      % Java classes that can be used:
      %     java.sql.Timestamp : handles nanoseconds
      %     java.util.Date     : handles milliseconds
      %
      % MATLAB is accurate to 0.01 milliseconds
      %----------------------------------------------------------------
      
      function javadate = mdate2jdate(matlabdate)
         %mdate2jdate converts a matlab date to a java Date class
         %  javadate = irisFetch.mdate2jdate(matlab_date)converts from matlab to java with
         %  millisecond precision.
         
         if ischar(matlabdate)
            matlabdate = datenum(matlabdate);
         end
         if ~isnumeric(matlabdate) || ~isscalar(matlabdate)
            error('IRISFETCH:mdate2jdate:incorrectDateFormat',...
               'A scalar matlab datenum was expected, but a different kind of value was received.');
         end
         
         jmillis = ((matlabdate-irisFetch.BASE_DATENUM) * irisFetch.MS_IN_DAY) + .5 ; % add 0.5 to keep it in sync.
         
         javadate = java.util.Date(jmillis); %convert to a Date, loosing nanosecond precision
         % javadate = java.util.Date(((datenum(matlabdate)-irisFetch.BASE_DATENUM) * irisFetch.MS_IN_DAY) + .5 )
      end
      
      %----------------------------------------------------------------
      % Look for GET / SET methods for the class.
      %----------------------------------------------------------------
      function M = getSettableFields(obj)
         % strip the first 3 letters off the field ('set')
         M        = irisFetch.getSetters(obj);
         startsWithSet=find(strncmp(M,'set',3));
         for n=1:numel(startsWithSet)
            M(startsWithSet(n))  = {M{startsWithSet(n)}(4:end)};
         end
      end
      %{
       function [M, argType] = getSetters(obj)
          [M, argType] = irisFetch.getMethods(obj,'set');
       end
      %}
      function [M, argType] = getSetters(obj)
         % assumption is that any function that returns a criteria object of the same class is
         % a "Set" method. The first time a class is encountered, it's set methods and
         % arguments are memorized.
         
         persistent className             % contains the list of classes that have already been done
         persistent listOfSetters         % contains a cell list of set-methods for each class
         persistent listOfArguments       % contains a cell list of inputs corresponding to each setter
         
         if isempty(className)
            className = {};
            listOfSetters={};
            listOfArguments={};
         end
         
         thisClass=class(obj);
         
         memorizedClass                 = strcmp(thisClass, className);
         
         if ~any(memorizedClass)
            classIndex                  = numel(className) + 1;
            className(classIndex)       = {thisClass};
            
            all_methods                 = methods(thisClass);
            full_methods                = methods(thisClass,'-full');
            is_setter                   = strcmp(thisClass, strtok(full_methods));
            [UNUSED_VARIABLE, setter_inputs]          = strtok(strtok(full_methods(is_setter),')'),'('); %#ok<ASGLU> %loose ()
            
            listOfArguments(classIndex) = {strrep(setter_inputs,'(','')};
            listOfSetters(classIndex)   = {all_methods(is_setter)};
            
            memorizedClass = strcmp(thisClass, className);
            % disp (['Adding ', thisClass, ' setters ...']);
         end
         
         M                             = listOfSetters{memorizedClass};
         argType                       = listOfArguments{memorizedClass};
      end
      
      function [methodList, argType] = getMethods(obj,searchPrefix)
         persistent className methodsAndArguments
         if isempty(className)
            className            = {''};
            methodsAndArguments  = {{''},{''}};
         end
         
         thisClass = class(obj);
         TF = strcmp(thisClass, className);
         if any(TF) % shortcut if this has been done before
            methodList  = methodsAndArguments{TF,1};
            argType     = methodsAndArguments{TF,2};
            return
         else
            loc = numel(className)+1;
         end
         
         
         argType     = {}; %methodList = [];
         M           = methods(obj);
         M2          = methods(obj,'-full');
         idx         = strncmp(searchPrefix,M, length(searchPrefix));
         methodList  = M(idx);
         argList     = M2(idx);
         
         p1          = strfind(argList,'(');
         p2          = strfind(argList,')');
         for n=1:numel(argList)
            argType(n) = {argList{n}(p1{n}+1:p2{n}-1)}; %#ok<AGROW>
         end
         
         className(loc)             = {thisClass};
         methodsAndArguments(loc,1) = {methodList};
         methodsAndArguments(loc,2) = {argType};
         
      end
      %%
      %================================================================
      %----------------------------------------------------------------
      % BEGIN: PARSING ROUTINES
      %----------------------------------------------------------------
      
      function [getterList, fieldList] = getMethodsAndFields(obj)
         
         
         % this function uses a cache to speed up the retrieval of
         % get_methods and fieldnames.
         
         persistent className
         persistent methodL
         persistent fieldL
         
         if isempty(className)
            className = {''};
            methodL = {''};
            fieldL = {''};
         end
         
         thisClass = class(obj);
         
         TF = strcmp(thisClass, className);
         
         if any(TF) % shortcut if this has been done before
            getterList = methodL{TF};
            fieldList = fieldL{TF};
            return
         else
            loc = numel(className)+1;
         end
         
         allMethods = methods(obj);
         getterList = allMethods(strncmp('get',allMethods, 3));
         
         % filter classes need class names for them to make sense to users.
         if isa(obj,'edu.iris.dmc.station.model.Filter')
            getterList = getterList(...
               ~( strcmp('get',getterList) | ...
               strcmp('getAny',getterList) ));
            
         else
            getterList = getterList(...
               ~( strcmp('get',getterList) | ...
               strcmp('getClass',getterList) | ...
               strcmp('getAny',getterList) ));
         end
         % eliminate recursions
         switch thisClass
            case 'edu.iris.dmc.station.model.Station'
               n = strcmp(getterList,'getNetwork');
            case 'edu.iris.dmc.station.model.StationEpoch'
               n = strcmp(getterList,'getStations');
            case 'edu.iris.dmc.station.model.Channel'
               n = strcmp(getterList,'getStationEpoch');
            case 'edu.iris.dmc.station.model.ChannelEpoch'
               n = strcmp(getterList,'getChannels');
            case 'edu.iris.dmc.station.model.Response'
               n = strcmp(getterList,'getChannelEpoch');
            case 'edu.iris.dmc.station.model.Sensor'
               n = strcmp(getterList,'getChannelEpoch');
            otherwise
               n=[];
         end
         getterList(n)  = [];
         
         fieldList      = strrep(getterList,'get',''); %get rid of 'get'
         
         className(loc) = {thisClass};
         methodL(loc)   = {getterList};
         fieldL(loc)    = {fieldList};
      end
      
      function out = parser_for_IRIS_WS_2_0_0(value)
         % call other classes based on this function
         
         out=irisFetch.parse(value, containers.Map);
      end
      
      function s = parse(value,stacklistt)
         % parse takes each value, looks up its class, and converts it to MATLAB
         % struct = parse(javaObject) recursively parses a java object. If the java object
         % contains objects of other java classes, then they will be parsed also.
         % 
         % struct = parse(javaObject, stacklistt)
         
         persistent stacklist
         if nargin == 2
            stacklist = stacklistt;
         end
         
         
         myClass = class(value);
         
         if irisFetch.recursionAssert
            try
               tf = stacklist(myClass);
            catch %#ok<CTCH>
               stacklist(myClass)= false;
               tf = false;
            end
            if tf
               % if stacklist(myClass)
               [x,UNUSED_VARIABLE] = dbstack(1); %#ok<NASGU> %remove this call from the stack, and get the list
               error(['\n\nRecursion detected. attempt to parse a\n  [%s] \n  '...
                  'when a parent of the same class exists.\n'...
                  'Please comment out the offending line of code (line %d)\n'],myClass,x(1).line);
            end
            stacklist(myClass)=true;
            
         end
         
         switch myClass
            
            case {'java.util.ArrayList'}
               if irisFetch.recursionAssert
                  stacklist(myClass)=false;
               end
               % disp(['parsing array of: ', class(value.get(0)) ]) ;
               for n=1 : value.size()
                  s(n)=irisFetch.parse(value.get(n-1)); %#ok<AGROW> % class(value.get(0))
               end
            case 'double'
               s=value;
            case {'edu.iris.dmc.fdsn.station.model.Dip' %MOVED
                  'edu.iris.dmc.fdsn.station.model.AngleType'
                  'edu.iris.dmc.fdsn.station.model.SampleRate'
                  'edu.iris.dmc.fdsn.station.model.SecondType'
                  'edu.iris.dmc.fdsn.station.model.VoltageType'
                  'edu.iris.dmc.fdsn.station.model.Frequency'
                  'edu.iris.dmc.fdsn.station.model.Azimuth'
                  'edu.iris.dmc.fdsn.station.model.Channel$ClockDrift'
                  'edu.iris.dmc.fdsn.station.model.Distance'
                  'edu.iris.dmc.fdsn.station.model.LongitudeBaseType'
                  'edu.iris.dmc.fdsn.station.model.LatitudeBaseType'
                  'edu.iris.dmc.fdsn.station.model.Float'
                  }
               s                  = value.getValue();
               % unused get routines: getUnit, getPlusError,getMinusError
               
            case {'edu.iris.dmc.timeseries.model.Timeseries'}
               s.NetworkCode             = char(value.getNetworkCode());
               s.StationCode             = char(value.getStationCode());
               s.Location                = char(value.getLocation());
               s.ChannelCode             = char(value.getChannelCode());
               s.DataQuality             = irisFetch.parse(value.getDataQuality()); % get char
               s.Segments                = irisFetch.parse(value.getSegments());    % get java.util.Collection
               
            case {'edu.iris.dmc.fdsn.station.model.FIR$NumeratorCoefficient'}
               s                   = value.getValue(); %was s.Value
               
            case {'edu.iris.dmc.fdsn.station.model.ResponseListElement'}
               s.Frequency               = irisFetch.parse(value.getFrequency());   % get edu.iris.dmc.fdsn.station.model.Frequency
               s.Amplitude               = irisFetch.parse(value.getAmplitude());   % get edu.iris.dmc.fdsn.station.model.Float
               s.Phase                   = irisFetch.parse(value.getPhase());       % get edu.iris.dmc.fdsn.station.model.AngleType
               
            case {'edu.iris.dmc.fdsn.station.model.RestrictedStatus'}
               s.value                   = char(value.value());
               s.values                  = irisFetch.parseAnArray(value.values());
               s.name                    = char(value.name());
               s.ordinal                 = value.ordinal();
               
            case {'edu.iris.dmc.fdsn.station.model.Sensitivity'}
               s.FrequencyStart          = double(value.getFrequencyStart());
               s.FrequencyEnd            = double(value.getFrequencyEnd());
               s.FrequencyDBVariation    = double(value.getFrequencyDBVariation());
               s.Value                   = value.getValue();
               s.Frequency               = value.getFrequency();
               s.InputUnits = irisFetch.addUnits(value.getInputUnits);
               s.OutputUnits = irisFetch.addUnits(value.getOutputUnits);
               % s.OutputUnitsName         = char(value.getOutputUnits().getName); % get edu.iris.dmc.fdsn.station.model.Units
               % s.OutputUnitsDescription  = char(value.getOutputUnits().getDescription); % get edu.iris.dmc.fdsn.station.model.Units
               
               
            case {'edu.iris.dmc.fdsn.station.model.Polynomial'}
               s.ApproximationType       = char(value.getApproximationType());
               s.Name                    = char(value.getName());
               s.Description             = char(value.getDescription());
               s.Coefficient = irisFetch.parseAnArray(value.getCoefficient());
               s.FrequencyLowerBound     = value.getFrequencyLowerBound().getValue; % get edu.iris.dmc.fdsn.station.model.Frequency
               s.FrequencyUpperBound     = value.getFrequencyUpperBound().getValue; % get edu.iris.dmc.fdsn.station.model.Frequency
               s.ApproximationLowerBound = value.getApproximationLowerBound().doubleValue;
               s.ApproximationUpperBound = value.getApproximationUpperBound().doubleValue;
               s.MaximumError            = value.getMaximumError().doubleValue;
               s.ResourceId              = char(value.getResourceId());
               s.InputUnits = irisFetch.addUnits(value.getInputUnits());  % get edu.iris.dmc.fdsn.station.model.Units
               s.OutputUnits = irisFetch.addUnits(value.getOutputUnits());  % get edu.iris.dmc.fdsn.station.model.Units
               
            case {'edu.iris.dmc.timeseries.model.Segment$Type'}
               s.values = irisFetch.parseAnArray(value.values());
               s.name                    = char(value.name());
               s.ordinal                 = value.ordinal();
               
               
            case {'edu.iris.dmc.fdsn.station.model.package-info'}
               
            case {'edu.iris.dmc.fdsn.station.model.BaseFilter'}
               s.Name                    = char(value.getName());
               s.Description             = char(value.getDescription());
               s.InputUnits = irisFetch.addUnits(value.getInputUnits);
               s.OutputUnits = irisFetch.addUnits(value.getOutputUnits);
               s.ResourceId              = char(value.getResourceId());
               
            case {'edu.iris.dmc.fdsn.station.model.LogType'}
               s.Entry = irisFetch.parseAnArray(value.getEntry());
               
            case {'edu.iris.dmc.fdsn.station.model.ResponseList'}
               s.ResponseListElement = irisFetch.parseAnArray(value.getResponseListElement());
               s.Name                    = char(value.getName());
               s.Description             = char(value.getDescription());
               s.InputUnits = irisFetch.addUnits(value.getInputUnits);
               s.OutputUnits = irisFetch.addUnits(value.getOutputUnits);
               s.ResourceId              = char(value.getResourceId());
               
            case {'edu.iris.dmc.fdsn.station.model.Units'}
               s.Name                    = char(value.getName());
               s.Description             = char(value.getDescription());
               
            case {'edu.iris.dmc.fdsn.station.model.ResponseStage'}
               s.Number                  = double(value.getNumber());
               s.PolesZeros              = irisFetch.parse(value.getPolesZeros());  % get edu.iris.dmc.fdsn.station.model.PolesZeros
               s.Coefficients            = irisFetch.parse(value.getCoefficients()); % get edu.iris.dmc.fdsn.station.model.Coefficients
               s.ResponseList            = irisFetch.parse(value.getResponseList()); % get edu.iris.dmc.fdsn.station.model.ResponseList
               s.FIR                     = irisFetch.parse(value.getFIR());         % get edu.iris.dmc.fdsn.station.model.FIR
               s.Polynomial              = irisFetch.parse(value.getPolynomial());  % get edu.iris.dmc.fdsn.station.model.Polynomial
               s.Decimation              = irisFetch.parse(value.getDecimation());  % get edu.iris.dmc.fdsn.station.model.Decimation
               s.StageGain               = irisFetch.parse(value.getStageGain());   % get edu.iris.dmc.fdsn.station.model.Gain
               
               
            case {'edu.iris.dmc.fdsn.station.model.SampleRateRatioType'}
               s.NumberSamples           = double(value.getNumberSamples());
               s.NumberSeconds           = double(value.getNumberSeconds());
               
            case {'edu.iris.dmc.fdsn.station.model.Decimation'}
               s.Offset                  = value.getOffset().doubleValue;
               s.Delay                   = irisFetch.parse(value.getDelay());       % get edu.iris.dmc.fdsn.station.model.Float
               s.InputSampleRate         = irisFetch.parse(value.getInputSampleRate()); % get edu.iris.dmc.fdsn.station.model.Frequency
               s.Factor                  = value.getFactor().doubleValue;
               s.Correction              = irisFetch.parse(value.getCorrection());  % get edu.iris.dmc.fdsn.station.model.Float
               
            case {'edu.iris.dmc.timeseries.model.Segment'}
               s.Type                    = irisFetch.parse(value.getType());        % get edu.iris.dmc.timeseries.model.Segment$Type
               s.StartTime               = irisFetch.parse(value.getStartTime());   % get java.sql.Timestamp
               s.EndTime                 = irisFetch.parse(value.getEndTime());     % get java.sql.Timestamp
               s.ShortData               = irisFetch.parseAnArray(value.getShortData());
               s.SampleCount             = value.getSampleCount();
               s.Samplerate              = value.getSamplerate();
               s.DoubleData              = irisFetch.parseAnArray(value.getDoubleData());
               s.FloatData               = irisFetch.parseAnArray(value.getFloatData());
               s.IntData                 = irisFetch.parseAnArray(value.getIntData());
               s.ExpectedNextSampleTime  = irisFetch.parse(value.getExpectedNextSampleTime()); % get java.sql.Timestamp
               
               
            case {'edu.iris.dmc.fdsn.station.model.PhoneNumberType'}
               s.Phone = sprintf('%s: [+%d] %03d %s',... % desc: [+country] area phonenum
                  char(value.getDescription()),...
                  double(value.getCountryCode()),...
                  double(value.getAreaCode()),...
                  char(value.getPhoneNumber()) );
               
            case {'edu.iris.dmc.sacpz.model.PZ',...
                  'edu.iris.dmc.fdsn.station.model.ComplexNumber',...
                  'edu.iris.dmc.sacpz.model.Zero',...
                  'edu.iris.dmc.fdsn.station.model.PoleZero',...
                  'edu.iris.dmc.sacpz.model.Pole'}
               s = complex(value.getReal.getValue(), value.getImaginary.getValue());
               
            case {'edu.iris.dmc.sacpz.model.PolesZeros'}
               s.Poles = irisFetch.parseAnArray(value.getPoles());
               s.Zeros = irisFetch.parseAnArray(value.getZeros());
               
            case {'edu.iris.dmc.fdsn.station.model.Filter'}
               s.Name                    = char(value.getName());
               s.Description             = char(value.getDescription());
               s.InputUnits = irisFetch.addUnits(value.getInputUnits);
               s.OutputUnits = irisFetch.addUnits(value.getOutputUnits);
               s.ResourceId              = char(value.getResourceId());
               
            case {'edu.iris.dmc.fdsn.station.model.FIR'}
               s.Symmetry                = char(value.getSymmetry());
               sz = value.getNumeratorCoefficient.size;
               if sz>0
                  s.NumeratorCoefficient=arrayfun(@getValue,value.getNumeratorCoefficient.toArray(javaArray('edu.iris.dmc.fdsn.station.model.FIR$NumeratorCoefficient',sz)));
                  % s.Numerator(sz,1)=0;
               else
                  s.NumeratorCoefficient=[];
               end
               value.getNumeratorCoefficient.clear;
               %s.NumeratorCoefficient = irisFetch.parseAnArray(value.getNumeratorCoefficient());
               s.Name                    = char(value.getName());
               s.Description             = char(value.getDescription());
               s.InputUnits = irisFetch.addUnits(value.getInputUnits);
               s.OutputUnits = irisFetch.addUnits(value.getOutputUnits);
               s.ResourceId              = char(value.getResourceId());
               
            case {'edu.iris.dmc.fdsn.station.model.DataAvailability'}
               s.Extent                  = irisFetch.parse(value.getExtent());      % get edu.iris.dmc.fdsn.station.model.DataAvailabilityExtent
               s.Span = irisFetch.parseAnArray(value.getSpan());
               
            case {'edu.iris.dmc.fdsn.station.model.RestrictedStatusType'}
               s.value                   = char(value.value());
               s.values = irisFetch.parseAnArray(value.values());
               s.name                    = char(value.name());
               s.ordinal                 = value.ordinal();
               
            case {'edu.iris.dmc.fdsn.station.model.Gain'}
               s.Value                   = value.getValue();
               s.Frequency               = value.getFrequency();
               
            case {'edu.iris.dmc.fdsn.station.model.Equipment'}
               s.Type                    = char(value.getType());
               s.SerialNumber            = char(value.getSerialNumber());
               s.Description             = char(value.getDescription());
               s.Model                   = char(value.getModel());
               s.Manufacturer            = char(value.getManufacturer());
               s.Vendor                  = char(value.getVendor());
               s.InstallationDate        = irisFetch.jdate2mdate(value.getInstallationDate());
               s.RemovalDate             = irisFetch.jdate2mdate(value.getRemovalDate());
               s.CalibrationDate = irisFetch.parseAnArray(value.getCalibrationDate());
               s.ResourceId              = char(value.getResourceId());
               
            case {'edu.iris.dmc.fdsn.station.model.DataAvailabilityExtent'}
               s.End                     = irisFetch.jdate2mdate(value.getEnd());
               s.Start                   = irisFetch.jdate2mdate(value.getStart());
               
               
            case {'edu.iris.dmc.fdsn.station.model.Coefficients'}
               s.CfTransferFunctionType  = char(value.getCfTransferFunctionType());
               sz = value.getNumerator.size;
               if sz>0
                  s.Numerator=arrayfun(@getValue,value.getNumerator.toArray(javaArray('edu.iris.dmc.fdsn.station.model.Float',sz)));
                  % s.Numerator(sz,1)=0;
               else
                  s.Numerator=[];
               end
               s.Denominator = irisFetch.parseAnArray(value.getDenominator());
               s.Name                    = char(value.getName());
               s.Description             = char(value.getDescription());
               s.InputUnits = irisFetch.addUnits(value.getInputUnits);
               s.OutputUnits = irisFetch.addUnits(value.getOutputUnits);
               s.ResourceId              = char(value.getResourceId());
               
            case {'edu.iris.dmc.sacpz.model.AbstractPZ'}
               s.Real                    = double(value.getReal());
               s.Imaginary               = double(value.getImaginary());
               
               %----------------------------------------------------------------------------------
               % EVENT
               %----------------------------------------------------------------------------------
            case {'edu.iris.dmc.event.model.Origin'}
               s.Time                    = irisFetch.jdate2mdate(value.getTime());
               s.Latitude                = value.getLatitude();
               s.Longitude               = value.getLongitude();
               s.Depth                   = value.getDepth() / 1000; %getDepth returns m. stored as km
               s.Author                  = char(value.getAuthor());
               s.Catalog                 = char(value.getCatalog());
               s.Contributor             = char(value.getContributor());
               s.ContributorOriginId     = char(value.getContributorOriginId());
               s.ContributorEventId      = char(value.getContributorEventId());
               s.PublicId                = char(value.getPublicId());
               s.Arrivals = irisFetch.parseAnArray(value.getArrivals());
               
            case {'edu.iris.dmc.event.model.Pick'}
               s.Location                = char(value.getLocation());
               s.Channel                 = char(value.getChannel());
               s.Time                    = irisFetch.jdate2mdate(value.getTime());
               s.Network                 = char(value.getNetwork());
               s.Station                 = char(value.getStation());
               s.PickId                  = char(value.getPickId());
               
            case {'edu.iris.dmc.event.model.Arrival'}
               s.PublicId                = char(value.getPublicId());
               s.Distance                = double(value.getDistance());
               s.Azimuth                 = double(value.getAzimuth());
               s.Phase                   = char(value.getPhase());
               s.Picks = irisFetch.parseAnArray(value.getPicks());
               s.TimeResidual            = double(value.getTimeResidual());
               
            case {'edu.iris.dmc.event.model.Magnitude'}
               s.Value                   = double(value.getValue());
               s.Type                    = char(value.getType());
               s.Author                  = char(value.getAuthor());
               s.PublicId                = char(value.getPublicId());
               s.OriginPublicId          = char(value.getOriginPublicId());
               
            case {'edu.iris.dmc.event.model.Event'}
               s.Type                    = char(value.getType());
               s.FlinnEngdahlRegionCode  = double(value.getFlinnEngdahlRegionCode());
               s.FlinnEngdahlRegionName  = char(value.getFlinnEngdahlRegionName());
               try
                  tmpPreferredOrigin         = irisFetch.parse(value.getPreferredOrigin()); % get edu.iris.dmc.event.model.Origin
               catch %#ok<CTCH>
                  tmpPreferredOrigin=[];
               end
               if ~isempty(tmpPreferredOrigin)
                  s.PreferredTime         = tmpPreferredOrigin.Time;
                  s.PreferredLatitude     = tmpPreferredOrigin.Latitude;
                  s.PreferredLongitude    = tmpPreferredOrigin.Longitude;
                  s.PreferredDepth        = tmpPreferredOrigin.Depth;
               else
                  [s.PreferredTime, s.PreferredLatitude, s.PreferredLongitude,s.PreferredDepth] = deal(nan);
               end
               tmpPreferredMagnitude      = irisFetch.parse(value.getPreferredMagnitude()); % get edu.iris.dmc.event.model.Magnitude
               if ~isempty(tmpPreferredMagnitude)
                  s.PreferredMagnitudeType = tmpPreferredMagnitude.Type;
                  s.PreferredMagnitudeValue = tmpPreferredMagnitude.Value;
               else
                  s.PreferredMagnitudeType = '';
                  s.PreferredMagnitudeValue = nan;
               end
               s.PreferredOrigin 	= tmpPreferredOrigin;
               s.Origins            = irisFetch.parseAnArray(value.getOrigins());
               s.PreferredMagnitude = tmpPreferredMagnitude;
               s.Magnitudes         = irisFetch.parseAnArray(value.getMagnitudes());
               s.Picks = irisFetch.parseAnArray(value.getPicks());
               s.PublicId           	 = char(value.getPublicId());
               
            case {'edu.iris.dmc.fdsn.station.model.Message'}
               s.Networks = irisFetch.parseAnArray(value.getNetwork());
               
            case {'edu.iris.dmc.sacpz.model.NumberUnit'}
               s.Value                   = double(value.getValue());
               s.Unit                    = char(value.getUnit());
               
            case {'edu.iris.dmc.fdsn.station.model.Comment'}
               s.Value                   = char(value.getValue());
               s.Id                      = double(value.getId());
               s.Author = irisFetch.parseAnArray(value.getAuthor());
               s.BeginEffectiveDate      = irisFetch.jdate2mdate(value.getBeginEffectiveDate());
               s.EndEffectiveDate        = irisFetch.jdate2mdate(value.getEndEffectiveDate());
               % s.BeginEffectiveTime      = irisFetch.jdate2mdate(value.getBeginEffectiveTime());
               % s.EndEffectiveTime        = irisFetch.jdate2mdate(value.getEndEffectiveTime());
               
            case {'edu.iris.dmc.fdsn.station.model.PolesZeros'}
               s.Zero = irisFetch.parseAnArray(value.getZero());
               s.PzTransferFunctionType  = char(value.getPzTransferFunctionType());
               s.NormalizationFactor     = value.getNormalizationFactor();
               s.Pole = irisFetch.parseAnArray(value.getPole());
               s.NormalizationFrequency  = irisFetch.parse(value.getNormalizationFrequency()); % get edu.iris.dmc.fdsn.station.model.Frequency
               s.Name                    = char(value.getName());
               s.Description             = char(value.getDescription());
               s.ResourceId              = char(value.getResourceId());
               s.InputUnits = irisFetch.addUnits(value.getInputUnits);
               s.OutputUnits = irisFetch.addUnits(value.getOutputUnits);
               
            case {'edu.iris.dmc.fdsn.station.model.DataAvailabilitySpan'}
               s.End                     = irisFetch.jdate2mdate(value.getEnd());
               s.Start                   = irisFetch.jdate2mdate(value.getStart());
               s.NumberSegments          = double(value.getNumberSegments());
               s.MaximumTimeTear         = double(value.getMaximumTimeTear());
               
            case {'edu.iris.dmc.fdsn.station.model.Site'}
               s.Name                    = char(value.getName());
               s.Country                 = char(value.getCountry());
               s.Description             = char(value.getDescription());
               s.Town                    = char(value.getTown());
               s.County                  = char(value.getCounty());
               s.Region                  = char(value.getRegion());
               
            case {'edu.iris.dmc.fdsn.station.model.Polynomial$Coefficient'}
               s = value.getValue();
               
            case {'edu.iris.dmc.fdsn.station.model.NominalType'}
               s.value                   = char(value.value());
               s.values = irisFetch.parseAnArray(value.values());
               s.name                    = char(value.name());
               s.ordinal                 = value.ordinal();
               
               
            case {'edu.iris.dmc.fdsn.station.model.Response'}
               s.InstrumentSensitivity   = irisFetch.parse(value.getInstrumentSensitivity()); % get edu.iris.dmc.fdsn.station.model.Sensitivity
               s.Stage = irisFetch.parseAnArray(value.getStage());
               s.InstrumentPolynomial    = irisFetch.parse(value.getInstrumentPolynomial()); % get edu.iris.dmc.fdsn.station.model.Polynomial
               
               
            case {'edu.iris.dmc.fdsn.station.model.Station$Operator'}
               s.Agency = irisFetch.parseAnArray(value.getAgency());
               s.Contact = irisFetch.parseAnArray(value.getContact());
               s.WebSite                 = char(value.getWebSite());
               
            case {'edu.iris.dmc.timeseries.model.Record'}
               s.Location = irisFetch.parseAnArray(value.getLocation());
               s.StartTime               = irisFetch.parse(value.getStartTime());   % get java.sql.Timestamp
               s.EndTime                 = irisFetch.parse(value.getEndTime());     % get java.sql.Timestamp
               s.SampleRate              = value.getSampleRate();
               s.ExpectedNextSampleTime  = irisFetch.parse(value.getExpectedNextSampleTime()); % get java.sql.Timestamp
               s.NumberOfSamples         = value.getNumberOfSamples();
               
            case {'edu.iris.dmc.fdsn.station.model.PersonType'}
               s.Name = irisFetch.parseAnArray(value.getName());
               s.Agency = irisFetch.parseAnArray(value.getAgency());
               s.Email = irisFetch.parseAnArray(value.getEmail());
               s.Phone = irisFetch.parseAnArray(value.getPhone());
               
            case {'edu.iris.dmc.fdsn.station.model.BaseNodeType'}
               assert('did not expect to get here');
               s.Comment = irisFetch.parseAnArray(value.getComment());
               s.Code                    = char(value.getCode());
               s.Description             = char(value.getDescription());
               s.StartDate               = irisFetch.jdate2mdate(value.getStartDate());
               s.EndDate                 = irisFetch.jdate2mdate(value.getEndDate());
               % s.StartTime               = irisFetch.jdate2mdate(value.getStartTime());
               % s.EndTime                 = irisFetch.jdate2mdate(value.getEndTime());
               % assert(strcmp(datestr(s.StartTime,31), datestr(s.StartDate,31)),'dates don''t match for network %s  %s vs %s\n',s.Code, datestr(s.StartTime,31), datestr(s.StartDate,31))
               s.DataAvailability        = irisFetch.parse(value.getDataAvailability()); % get edu.iris.dmc.fdsn.station.model.DataAvailability
               s.RestrictedStatus        = char(value.getRestrictedStatus());
               s.AlternateCode           = char(value.getAlternateCode());
               s.HistoricalCode          = char(value.getHistoricalCode());
               
               
            case {'edu.iris.dmc.fdsn.station.model.Channel'}
               s.ChannelCode                    = char(value.getCode());
               s.LocationCode            = char(value.getLocationCode());
               s.Description             = char(value.getDescription());
               s.Type = char(value.getType());
               s.Response                = irisFetch.parse(value.getResponse());    % get edu.iris.dmc.fdsn.station.model.Response
               % take the instrument sensitivity. These values are the INPUT units, which
               % matches previous irisFetch
               if isstruct(s.Response.InstrumentSensitivity)
                  s.SensitivityFrequency= s.Response.InstrumentSensitivity.Frequency;
                  s.SensitivityUnitDescription = s.Response.InstrumentSensitivity.InputUnits{2};
                  s.SensitivityUnits = s.Response.InstrumentSensitivity.InputUnits{1};
                  s.SensitivityValue = s.Response.InstrumentSensitivity.Value;
               else
                  s.SensitivityFrequency = NaN;
                  s.SensitivityUnitDescription = '';
                  s.SensitivityUnits = '';
                  s.SensitivityValue = NaN;
               end
               
               s.Equipment               = irisFetch.parse(value.getEquipment());   % get edu.iris.dmc.fdsn.station.model.Equipment
               s.SampleRateRatio         = irisFetch.parse(value.getSampleRateRatio()); % get edu.iris.dmc.fdsn.station.model.SampleRateRatioType
               s.StorageFormat           = char(value.getStorageFormat());
               s.ClockDrift              = irisFetch.parse(value.getClockDrift());  % get edu.iris.dmc.fdsn.station.model.Channel$ClockDrift
               s.DataLogger              = irisFetch.parse(value.getDataLogger());  % get edu.iris.dmc.fdsn.station.model.Equipment
               s.Sensor                  = irisFetch.parse(value.getSensor());      % get edu.iris.dmc.fdsn.station.model.Equipment
               s.PreAmplifier            = irisFetch.parse(value.getPreAmplifier()); % get edu.iris.dmc.fdsn.station.model.Equipment
               s.ExternalReference = irisFetch.parseAnArray(value.getExternalReference());
               
               s.Latitude           = value.getLatitudeValue().doubleValue;
               s.Longitude          = value.getLongitudeValue().doubleValue;
               s.Elevation          = value.getElevationValue().doubleValue;
               s.Depth              = value.getDepthValue().doubleValue;
               s.Azimuth            = value.getAzimuthValue().doubleValue;
               s.Dip                = value.getDipValue().doubleValue;
               
               s.SampleRate         = value.getSampleRateValue().doubleValue;
               
               s.CalibrationUnits        = irisFetch.parse(value.getCalibrationUnits()); % get edu.iris.dmc.fdsn.station.model.Units
               %         s.Comment = irisFetch.parseAnArray(value.getComment());
               %s.StartTime               = irisFetch.jdate2mdate(value.getStartTime());
               s.StartDate               = irisFetch.jdate2mdate(value.getStartDate());% duplicates StartTime ( but using org.apache.xerces.jaxp.datatype.XMLGregorianCalendarImpl)
               %s.EndTime                 = irisFetch.jdate2mdate(value.getEndTime());
               s.EndDate                 = irisFetch.jdate2mdate(value.getEndDate());% duplicates EndTime ( but using org.apache.xerces.jaxp.datatype.XMLGregorianCalendarImpl)
               s.DataAvailability        = irisFetch.parse(value.getDataAvailability()); % get edu.iris.dmc.fdsn.station.model.DataAvailability
               s.RestrictedStatus        = char(value.getRestrictedStatus());
               s.AlternateCode           = char(value.getAlternateCode());
               s.HistoricalCode          = char(value.getHistoricalCode());
               
            case {'edu.iris.dmc.fdsn.station.model.Station'}
               % s.Network                 = irisFetch.parse(value.getNetwork());     % get edu.iris.dmc.fdsn.station.model.Network
               s.StationCode                    = char(value.getCode());
               % s.AlternateCode           = char(value.getAlternateCode());
               % s.Channel                = irisFetch.parseAnArray(value.getChannels());
               s.Latitude                = value.getLatitude().getValue();    % get edu.iris.dmc.fdsn.station.model.Latitude
               s.Longitude               = value.getLongitude().getValue();   % get edu.iris.dmc.fdsn.station.model.Longitude
               s.Elevation               = irisFetch.parse(value.getElevation());   % get edu.iris.dmc.fdsn.station.model.Distance
               s.Site                    = irisFetch.parse(value.getSite());        % get edu.iris.dmc.fdsn.station.model.Site
               % s.Vault                   = char(value.getVault());
               % s.Geology                 = char(value.getGeology());
               % s.Equipment = irisFetch.parseAnArray(value.getEquipment());
               % s.Operator = irisFetch.parseAnArray(value.getOperator());
               % s.CreationDate            = irisFetch.jdate2mdate(value.getCreationDate());
               % s.TerminationDate         = irisFetch.jdate2mdate(value.getTerminationDate());
               % s.ExternalReference = irisFetch.parseAnArray(value.getExternalReference());
               s.Comment = irisFetch.parseAnArray(value.getComment());
               s.Description             = char(value.getDescription());
               %s.StartTime               = irisFetch.jdate2mdate(value.getStartTime());
               %s.EndTime                 = irisFetch.jdate2mdate(value.getEndTime());
               s.StartDate               = irisFetch.jdate2mdate(value.getStartDate()); % duplicates StartTime ( but using org.apache.xerces.jaxp.datatype.XMLGregorianCalendarImpl)
               s.EndDate                 = irisFetch.jdate2mdate(value.getEndDate()); % duplicates EndTime ( but using org.apache.xerces.jaxp.datatype.XMLGregorianCalendarImpl)
               s.DataAvailability        = irisFetch.parse(value.getDataAvailability()); % get edu.iris.dmc.fdsn.station.model.DataAvailability
               s.RestrictedStatus        = char(value.getRestrictedStatus());
               %s.HistoricalCode          = char(value.getHistoricalCode());
               s.Channels                = irisFetch.parseAnArray(value.getChannels());
               s.TotalNumberChannels     = double(value.getTotalNumberChannels());
               s.SelectedNumberChannels  = double(value.getSelectedNumberChannels());
               
            case {'edu.iris.dmc.fdsn.station.model.Network'}
               s.NetworkCode                    = char(value.getCode());
               s.Description             = char(value.getDescription());
               s.Comment                 = irisFetch.parseAnArray(value.getComment());
               %s.StartTime               = irisFetch.jdate2mdate(value.getStartTime());
               s.StartDate               = irisFetch.jdate2mdate(value.getStartDate());% duplicates StartTime ( but using org.apache.xerces.jaxp.datatype.XMLGregorianCalendarImpl)
               %s.EndTime                 = irisFetch.jdate2mdate(value.getEndTime());
               s.TotalNumberStations     = double(value.getTotalNumberStations());
               s.SelectedNumberStations  = double(value.getSelectedNumberStations());
               s.EndDate                 = irisFetch.jdate2mdate(value.getEndDate()); % duplicates EndTime ( but using org.apache.xerces.jaxp.datatype.XMLGregorianCalendarImpl)
               s.DataAvailability        = irisFetch.parse(value.getDataAvailability()); % get edu.iris.dmc.fdsn.station.model.DataAvailability
               s.Stations                = irisFetch.parseAnArray(value.getStations());
               s.RestrictedStatus        = char(value.getRestrictedStatus());
               % s.AlternateCode           = char(value.getAlternateCode());
               % s.HistoricalCode          = char(value.getHistoricalCode());
               
               
            case {'edu.iris.dmc.sacpz.model.Sacpz'}
               s.Location                = char(value.getLocation());
               s.Channel                 = char(value.getChannels());
               s.Comment                 = char(value.getComment());
               s.StartTime               = irisFetch.jdate2mdate(value.getStartTime());
               s.Description             = char(value.getDescription());
               s.Depth                   = double(value.getDepth());
               s.Azimuth                 = double(value.getAzimuth());
               s.Elevation               = double(value.getElevation());
               s.EndTime                 = irisFetch.jdate2mdate(value.getEndTime());
               s.SampleRate              = double(value.getSampleRate());
               s.Network                 = char(value.getNetwork());
               s.Station                 = char(value.getStations());
               s.Latitude                = value.getLatitude().getValue();
               s.Longitude               = value.getLongitude().getValue();
               s.Sensitivity             = irisFetch.parse(value.getSensitivity()); % get edu.iris.dmc.sacpz.model.NumberUnit
               s.Created                 = irisFetch.jdate2mdate(value.getCreated());
               s.Poles                 = irisFetch.parseAnArray(value.getPoles());
               s.Zeros                 = irisFetch.parseAnArray(value.getZeros());
               s.Inclination             = double(value.getInclination());
               s.InputUnit               = char(value.getInputUnit());
               s.OutputUnit              = char(value.getOutputUnit());
               s.InstrumentType          = char(value.getInstrumentType());
               s.InstrumentGain          = irisFetch.parse(value.getInstrumentGain()); % get edu.iris.dmc.sacpz.model.NumberUnit
               s.A0                      = double(value.getA0());
               s.Constant                = value.getConstant();
               
            otherwise
               warning('IRISFETCH:parse:classNotFound','%s was not found',myClass)%who knows?
         end % cases
         if irisFetch.recursionAssert
            stacklist(myClass)=false;
         end
      end  % main function
      
      function matlabdate = jdate2mdate(javadate)
         if isempty(javadate)
            matlabdate = [];
            return;
         end
         % NOTE: Matlab cannot provide nanosecond resolution, though it can come close...
         switch class(javadate)
            case 'java.sql.Timestamp' % nanosecond precision
               matlabdate = datenummx(1970, 1, 1, 0, 0, (fix(javadate.getTime()/1000) + javadate.getNanos / 1000000000));
            case 'java.util.Date' % millisecond precision
               matlabdate = datenummx(1970, 1, 1, 0, 0, javadate.getTime()/1000);
            case{'javax.xml.datatype.XMLGregorianCalendar',...
                  'org.apache.xerces.jaxp.datatype.XMLGregorianCalendarImpl'}
               if isempty(javadate.getFractionalSecond)
                  mySecond=javadate.getSecond;
               else
                  mySecond=javadate.getSecond + double(javadate.getFractionalSecond);
               end
               matlabdate= datenummx(...
                  javadate.getYear, javadate.getMonth,  javadate.getDay, ...
                  javadate.getHour, javadate.getMinute, mySecond);
            otherwise
               matlabdate= datenum(strrep(char(javadate.toString),'T',' ')); % this will probably crash
         end
         matlabdate=datestr(matlabdate, irisFetch.DATE_FORMATTER);
      end %fn jdate2mdate
      
      function s = addUnits(theUnit)
         if ~isempty(theUnit)
            s         = { char(theUnit.getName), char(theUnit.getDescription) };  % get edu.iris.dmc.fdsn.station.model.Units
         else
            s = {'',''};
         end
      end
      
      function s = parseAnArray(theArray)
         persistent getAz getDis getResid
         if isempty(getAz) || isempty(getDis) || isempty(getResid)
            getAz    =@(x) double(x.getAzimuth());
            getDis   =@(x) double(x.getDistance());
            getResid =@(x) double(x.getTimeResidual());
         end
         if isnumeric(theArray),
            s = theArray;
            return
         end
         
         arraySize = theArray.size();
         if arraySize == 0,
            s=[];
            return
         end
         
         firstItem = theArray.get(0);
         
         if isjava(firstItem)
            switch class(firstItem)
               case {'edu.iris.dmc.fdsn.event.model.Event'}
                  disp('counter detailing the event')
               case {'edu.iris.dmc.fdsn.station.model.Network'}
                  disp('counter detailing network');
            end
            for nn=arraySize : -1 : 1
               s(nn)= irisFetch.parse(theArray.get(nn-1));
            end
            theArray.clear;
            return
         end
         
         if arraySize == 1
            s=firstItem;
         elseif ischar(firstItem)
            s=char(theArray);
         else % the array doesn't contain java or text, so it's probably just numbers.
            try
               s=double(theArray.toArray(javaArray('java.lang.Double',arraySize)));
            catch er
               disp(er.message)
               fprintf('unable to convert %s as though it were numbers.\n', class(theArray.get(0)));
               for nn=arraySize:-1:1
                  s(nn)={theArray.get(nn-1)};% create a cell
               end
            end
         end
         theArray.clear;
      end %fn parseAnArray
      
      %----------------------------------------------------------------
      % END: PARSING ROUTINES
      %----------------------------------------------------------------
      %================================================================
      %%
      
      function crit = addCriteria(crit, value, addMethod)
         %used to add Sta, Net, Loc, Chan to criteria
         % For example:
         %   singleAddToCriteria(criteria, {'OKCF','MNO?'},'addStation')
         % will invoke:
         %   criteria.addStation('OKCF').addStation('MNO?')
         
         if isempty(value)
            return %do nothing
         end
         if ~iscell(value)
            % it's probably a string
            crit.(addMethod)(value);
         else
            % a cell may have multiple values.
            for n=1:numel(value)
               crit.(addMethod)(value{n});
            end
         end
      end
      
      function crit = setBoxCoordinates(crit, value)
         % setBoxCoordinates (minLat, maxLat, minLon, maxLon)
         % values of 'NAN' are ignored
         assert(numel(value)==4,'IRISFETCH:setBoxCoordinates:InvalidParameterCount',...
            'Expected [minLat, maxLat, minLon, maxLon]');
         
         setMethods = {'setMinimumLatitude','setMaximumLatitude',...
            'setMinimumLongitude','setMaximumLongitude'};
         for n=1:numel(setMethods)
            if ~isnan(value(n))
               crit.(setMethods{n})(java.lang.Double(value(n)));
            end
         end
      end
      
      function crit = setCriteria(crit, paramList)
         
         %----------------------------------------------------------
         % The following code allows for open-ended search criteria
         % that can change when the java library changes
         %
         % Instead of hard-coding each Setter, query the java class to determine its set methods
         %
         % Also determine the input parameters for each setter, then
         % use that to properly create/cast the data.
         %----------------------------------------------------------
         
         % Get a list of parameters, their set functions, and input
         % types, and do it outside the loop so they are not needlessly
         % rerun
         
         [allSetMethods, argType]   = irisFetch.getSetters(crit);
         settableFieldnames         = irisFetch.getSettableFields(crit);
         allMethods                 = methods(crit);
         
         while ~isempty(paramList) && numel(paramList) >= 2
            
            % Grab the parameter pair, then remove from parameter list
            [param value] = deal(paramList{1:2});
            paramList(1:2)=[];
            
            indexOfMethod = strcmpi(param,settableFieldnames);
            
            if any(indexOfMethod)
               try
                  converter=irisFetch.M2J_MAP(argType{indexOfMethod});
               catch er
                  disp(er.message)
                  fprintf('Unanticipated argument type [%s]... trying\n',argType{indexOfMethod});
                  converter=@(x) x;
               end
               crit.(allSetMethods{indexOfMethod})(converter(value));
               continue
            end % if any
            
            % we shall only pass this point if existing methods were not used
            
            switch lower(param)
               %handle special cases
               case 'boxcoordinates'
                  crit = irisFetch.setBoxCoordinates(crit, value);
                                    
               case 'radialcoordinates'
                  crit.setLatitude(java.lang.Double(value(1)));
                  crit.setLongitude(java.lang.Double(value(2)));
                  crit.setMaximumRadius(java.lang.Double(value(3)));
                  if numel(value) ==4 && ~isnan(value(4))
                     crit.setMinimumRadius(java.lang.Double(value(4)));
                  end
                  
                  
               case 'includeavailability' 
                  assert((islogical(value)||isnumeric(value)) &&isscalar(value),'The value of IncludeAvailability should be a scalar logical: true or false (no quotes)');
                  crit.setIncludeAvailability(value);
               case 'includerestricted'
                  assert((islogical(value)||isnumeric(value)) &&isscalar(value),'The value of IncludeRestricted should be a logical: true or false (no quotes)');
                  crit.setIncludeRestricted(value);
               case 'matchtimeseries'
                  assert((islogical(value)||isnumeric(value)) &&isscalar(value),'The value of MatchTimeseries should be a logical: true or false (no quotes)');
                  crit.setMatchTimeSeries(value);
                  
               case 'limit'
                  crit.setFetchLimit(java.lang.Integer(value));
               otherwise
                  try
                     % this will blow up if java doesn't recognize "value"
                     crit.(allMethods{strcmpi(allMethods,param)})(value);
                  catch
                     switch(class(value))
                        case 'double'; value=num2str(value);
                        case 'logical'; if value; value='true'; else value='false'; end
                     end
                     assert(ischar(value),'IRISFETCH:Event:InvalidParameterPair','When adding arbitrary parameter pairs, value must be a string. In this case, %s=<%s>',param,class(value));
                     crit.add(param,value); %as of 2.0.2 can add arbitrary parameter/value pairs.
                  end
                  % %this will blow up if java doesn't recognize "value"
                  % crit.(allMethods{strcmpi(allMethods,param)})(value);
            end
         end
      end
   end %static protected methods
end

