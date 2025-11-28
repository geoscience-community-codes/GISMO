classdef irisFetch

   % IRISFETCH allows seamless access to data stored within the IRIS-DMC via FDSN services
   %
   % irisFetch Methods:
   %
   % irisFetch waveform retrieval Methods:
   %    Traces - retrieve sac-equivalent waveforms with channel metadata
   %    SACfiles - as Traces above, but saves directly to a SAC file.
   %
   % irisFetch FDSN station webservice Methods:
   %    Channels - retrieve metadata as an array of channels
   %    Stations - retrieve metadata as an array of stations
   %    Networks - retrieve metadata as an array of networks
   %
   % irisFetch FDSN event webservice Methods:
   %    Events - retrieve events parameters (such as origins and magnitudes) from a catalog
   %
   % irisFetch miscellaneous Methods:
   %    Resp - retrive RESP formatted response data from the irisws-resp service
   %    version - display the current version number
   %    connectToJar - attempt to connect to the required IRIS-WS JAR file
   %    runExamples - displays and runs some sample queries to the web service
   %    Trace2SAC - writes a trace structure to a SAC file
   %    SAC2Trace - reads one or more locally stored SAC files to a trace structure
   %
   %  irisFetch requires version 2.0 or greater of the IRIS Web Services Library java jar
   %  for more details, click on 'connectToJar' above.
   %
   %  For additional guidance, type help <method>, use irisFetch.runExamples, or check out
   %  the online manual https://ds.iris.edu/dms/nodes/dmc/software/downloads/irisFetch.m/
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
     VERSION           = '2.0.12';  % irisFetch version number
     DATE_FORMATTER    = 'yyyy-mm-dd HH:MM:SS.FFF'; %default data format, in ms
     MIN_JAR_VERSION   = '2.0.15'; % minimum version of IRIS-WS jar required for compatibility

     VALID_QUALITIES   = {'D','R','Q','M','B'}; % list of Qualities accepted by Traces
     DEFAULT_QUALITY   = 'M'; % default Quality for Traces
     FETCHER_LIST      = {'Traces','Stations','Events','Resp'}; % list of functions that fetch
     forceDataAsDouble = true; %require that traces are returned as doubles regardless of original format
   end %constant properties

   properties (Constant = true, Hidden = true)
      MS_IN_DAY         = 86400000; % milliseconds in day
      BASE_DATENUM      = 719529; % Matlab startdate=0000-Jan-1 vs java's startdate=1970-Jan-1
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
      FEDERATOR_TRIGGER = 'FEDERATED';
      FEDERATOR_BASEURL = 'http://service.iris.edu/irisws/fedcatalog/1/';
      FEDERATOR_LABELS = {'DATACENTER','RESPSERVICE','EVENTSERVICE','STATIONSERVICE','DATASELECTSERVICE','SACPZSERVICE','AVAILABILITYSERVICE'};
   end %hidden constant properties

   methods(Static)
      function v = version()
         v = irisFetch.VERSION;
      end

      function Trace2SAC(traces, writeDirectory, verbosity)
         % irisFetch.Trace2SAC(traces, writeDirectory)
         %
         % Writes a trace structure to a SAC file within 'writeDirectory'
         % All output SAC filenames are automatically generated.
         %
         %   INPUTS
         %     traces: the Traces struct for writting to SAC file(s).
         %     writeDirectory: name of output directory

         if ~exist('verbosity','var')
            verbosity = false;
         end
         irisFetch.write_sac_out(writeDirectory, traces, verbosity);
      end

      function tr = SAC2Trace(file_dir_name)
          % tr = irisFetch.SAC2Trace(file_dir_name)
          %
          % Reads in SAC file(s) into a Trace structure.
          % NOTE: Only binary SAC files are supported at this time.
          %
          %   INPUTS
          %     file_dir_name: Name of input file(s) or directory
          %       -If a directory is specified, then all files within that
          %       directory with the extension .sac or .SAC will be loaded.
          %       -Wildcard characters ('*' or '?') are valid.
          %
          %   OUTPUTS
          %     tr: Trace structure, as returned by irisFetch.Traces

          tr = irisFetch.read_sac_in(file_dir_name);
      end

      %% TRACE/DATASELECT related STATIC, PUBLIC routines

      function SACfiles(network, station, location, channel, startDate, endDate, writeDirectory, varargin)
         % irisFetch.SACfiles(network, station, location, channel, startDate, endDate, writeDirectory,...)
         %   As with irisFetch.Traces, but waveform data will be written out as SAC files
         %   to a directory specified by 'writeDirectory'
         %
         %   The 'writeDirectory' parameter is mandatory. If 'writeDirectory' does not exist, then
         %   it will be created.
         %
         %   NOTE: unlike the Traces method, no structures will be saved in your MATLAB workspace
         %   if this method is used.
         %
         %   see irisFetch.Traces for more information on specifying channel identifier inputs

         irisFetch.Traces(network, station, location, channel, startDate, endDate, ['WRITESAC:', writeDirectory], 'ASJAVA', varargin{:});
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
         %  tr = irisFetch.Traces(...,'federated') first queries the
         %  fedcatalog service to determine the holdings from each
         %  datacenter that match the request.  Then, irisFetch retrieves
         %  the traces from the datacenter. See additional FEDERATED note
         %  below.
         %
         %  tr = irisFetch.Traces(..., urlbase) will allow traces to be read from an
         %  alternate data center. url base is only the first part of the web address. For
         %  example, the IRIS datacenter would be 'http://service.iris.edu/'. These
         %  settings are "sticky", so that all calls for waveform data or station metadata
         %  will go to that datacenter until a new one is specified.
         %
         %  tr = irisFetch.Traces(..., 'DATASELECTURL:http://host/path/to/dataselect')
         %  will explicity set the URL to the fdsnws-dataselect web service to fetch
         %  time series data from.
         %
         %  tr = irisFetch.Traces(..., 'STATIONURL:http://host/path/to/dataselect')
         %  will explicity set the URL to the fdsnws-station web service to fetch
         %  metadata data from.
         %
         %  tr = irisFetch.Traces(..., 'WRITESAC:writeDir') will retrieve seismic traces
         %  and then write a SAC file to the directory specified by 'writeDir' for each
         %  trace structure. This method will also store the retrieved waveform data in
         %  the MATLAB workspace.
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
         %  ABOUT FEDERATED DATA
         %    When traces are received via the "federated" catalog, they
         %    are grouped by datacenter.  The result will be a structure,
         %    containing fields with the name of the data center.
         %    Using a concrete example, if I request:
         %      tr = irisFetch.Traces('?R','A*','*','BHZ','2010-02-27 6:30:00','2010-02-27 6:31:00','federated')
         %
         %    irisFetch first queries the federator service located at:
         %        http://service.iris.edu/irisws/fedcatalog/1/
         %    which returns matches at three datacenters:
         %       3 matches at BGR (http://eida.bgr.de)
         %       9 matches at IRISDMC (http://service.iris.edu)
         %       4 matches at RESIF (http://www.resif.fr)
         %    it then retrieves each trace, one after the other. Placing
         %    them into a final structure which contains the data that was
         %    successfully retrieved:
         %       tr =
         %           BGR: [1x3 struct]
         %       IRISDMC: [1x7 struct]
         %         RESIF: [1x2 struct]
         %
         %  * Side effect of retrieving data from other datacenters:
         %    The java library used by irisfetch remembers the last
         %    datacenter. So if you then try to retrieve data without the
         %    'federated' method, it might search in the wrong center.  To
         %    fix, either clear java or send a federated request that finds
         %    data at your specific datacenter.
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
                  
         if ~exist('edu.iris.dmc.extensions.fetch.TraceData','class')
            irisFetch.connectToJar()
         end

         import edu.iris.dmc.*

         safeLocation = @(x) strrep(x,' ','-');
         str2webdate = @(x) strrep(x,' ', 'T'); % 'YYYY-MM-DD hh:mm:ss' -> 'YYYY-MM-DDThh:mm:ss'
         web2strdate = @(x) strrep(x,'T',' ');

         opts = setOptions(varargin);
         dbPrint = irisFetch.getDBfprintf(opts.verbosity);
         location = safeLocation(location);

         tracedata = edu.iris.dmc.extensions.fetch.TraceData();
         tracedata.setAppName(irisFetch.appName);
         tracedata.setVerbosity(opts.verbosity);

         % Set new base URL if specified
         if ~isempty(opts.newbase)
             if strcmp(opts.newbase(end),'/')
                 opts.newbase = opts.newbase(1:end-1);
             end
             tracedata.setBASE_URL(opts.newbase);
             dbPrint('Using services at base: %s\n', opts.newbase);
         end

         % Set specific service URLs if specified
         if ~isempty(opts.dataselectURL)
             tracedata.setWAVEFORM_URL(opts.dataselectURL);
             dbPrint('Using dataselect service at: %s\n', opts.dataselectURL);
         end
         if ~isempty(opts.stationURL)
             tracedata.setSTATION_URL(opts.stationURL);
             dbPrint('Using station service at: %s\n', opts.stationURL);
         end

         if ~opts.useFederator
            ts = getTheTraces(network, station, location, channel, startDate, endDate, opts);
         else
            ts = getResultsFromFederator(network, station, location, channel, startDate, endDate, opts);
         end

         return

         % ---------------------------------------------------------------
         % END TRACES: MAIN
         % ===============================================================

         function [svc, url, mykey] = parseFederatedHeaderLine(A)
            [svc,A] = splitString(A,'=');
            assert(ismember(svc, irisFetch.FEDERATOR_LABELS), '%s isn''t a known label\n',svc);
            switch svc
               case 'DATACENTER'
                  [mykey, url] = splitString(A,',');
               otherwise
                  mykey = '';
                  url = A;
            end
         end

         function [s1, s2] = splitString(s, tok)
            [s1, s2] = strtok(s, tok);
            if ~isempty(s2)
               s2(1)='';
            end
         end

         function tracesByDatacenter = getResultsFromFederator(network, station, location, channel, startDateStr, endDateStr, opts)
            tracesByDatacenter = struct;
            stD = str2webdate(irisFetch.makeDateStr(startDateStr));
            edD = str2webdate(irisFetch.makeDateStr(endDateStr));
            q = sprintf('net=%s&sta=%s&loc=%s&cha=%s&start=%s&end=%s',...
               network, station, location, channel, stD, edD);
            fullquery = [irisFetch.FEDERATOR_BASEURL, 'query?',  q];
            dbPrint('Fetching federator catalog results :: ');
            fedResults = webread(fullquery);
            dbPrint('%d Bytes\n',numel(fedResults));
            dbPrint(fedResults)
            assignin('base','fedResults',fedResults);

            a = textscan(fedResults, '%s %s %s %s %s %s');
            nets = a{1}; stas = a{2}; locs = a{3}; chas = a{4};
            stts = a{5}; edts = a{6};

            isHeader = cellfun(@isempty, stas);
            starttimer = tic;
            dstic = [];
            for row = 1 : numel(nets)
               if isHeader(row)
                  [svc, url, newDataCenter] = parseFederatedHeaderLine(nets{row});
                  if newDataCenter
                     flush()
                     currDataCenter = newDataCenter;
                     fprintf('Fetching data from %s (%s)\n',...
                        newDataCenter, url)
                  end
                  switch svc
                      case 'DATASELECTSERVICE'
                         tracedata.setWAVEFORM_URL(url);
                      case 'SACPZSERVICE'
                          % setting SACPZ url service will not work until
                          % library is patched. Currently, setSACPZ_URL
                          % method will always append "/irisws/sacpz/1/"
                          %   tracedata.setSACPZ_URL(url)
                        sacpz_svc_incl = 1;
                      case 'STATIONSERVICE'
                         tracedata.setSTATION_URL(url);
                  end
                  dbPrint('[%s] : %-10s > %s\n',currDataCenter, svc, url);
               else
                  network = nets{row};
                  station = stas{row};
                  location = locs{row};
                  channel = chas{row};
                  startDateStr = web2strdate(stts{row});
                  endDateStr = web2strdate(edts{row});

                  % Check if datacenter includes a sacpz web service, edit
                  % opts.sacpz field if no service available.
                  if exist('sacpz_svc_incl','var')
                      opts.getsacpz = 1;
                  else
                      opts.getsacpz = 0;
                  end

                  dbPrint('query : %s\n', q);
                  tmp = getTheTraces(network, station, location, channel, startDateStr, endDateStr, opts);
                  if exist('ts','var')
                     ts = [ts tmp];
                  else
                     ts = tmp;
                  end
               end
            end
            flush()
            fprintf('DONE at %s (Total time:%3.1f seconds)\n',datestr(now),toc(starttimer));
            function flush()
               if exist('ts','var')
                  tracesByDatacenter.(currDataCenter) = ts;
                  fprintf('Received %d channels in %3.1f seconds\n',...
                     numel(ts), toc(dstic) );
                  clear ts
               end
               dstic = tic;
            end
         end

         function opts = getUserOptions(opts, argList)
            % extracts getsacpz, verbosity, authorize, quality, username, and userpwd
            % Parameters are handled "intelligently" so that [paramname, paramval] pairs
            % aren't necessry

            for n=1:numel(argList)
               param = argList{n};
               switch class(param)
                  case 'cell'
                     assert(numel(param)==2 && all(cellfun(@ischar, param)),...
                        'A cell parameter is assumed to contain credentials. eg. {''nobody@iris.edu'',''anonymous''}.');
                     [opts.username, opts.userpwd] = deal(param{:});
                     opts.authorize         = true;
                  case 'char'
                     switch upper(param)
                        case irisFetch.VALID_QUALITIES
                           opts.quality     = param;
                        case {'INCLUDEPZ'}
                           opts.getsacpz    = true;
                        case {'VERBOSE'}
                           opts.verbosity   = true;
                        case {'ASJAVA'}
                           opts.convertToMatlab = false;
                        case {'SACONLY'}
                           opts.convertToMatlab = false;
                           opts.getsacpz = false;
                           opts.saveSAC = true;
                           opts.writeDirectory = pwd;
                        case {irisFetch.FEDERATOR_TRIGGER}
                           opts.useFederator = true;
                        otherwise

                           if length(param)>7 && strcmpi(param(1:7),'http://')
                              % set service base
                              opts.newbase = param;
                           elseif length(param)>8 && strcmpi(param(1:8),'https://')
                               % set service base
                               opts.newbase = param;
                           elseif length(param) > 13 && strcmpi(param(1:13),'DATASELECTURL')
                              % expecting 'DATASELECTURL:http://host/path/to/dataselect'
                              opts.dataselectURL = param(15:end);
                           elseif length(param) > 10 && strcmpi(param(1:10),'STATIONURL')
                              % expecting 'STATIONURL:http://host/path/to/station'
                              opts.stationURL = param(12:end);
                           elseif length(param) >= 8 && strcmpi(param(1:8),'WRITESAC')
                              % expecting 'WRITESAC' or
                              % 'WRITESAC:full/directory/path'
                              opts.saveSAC = true;
                              if length(param) <9
                                 opts.writeDirectory = pwd;
                              else
                                 opts.writeDirectory = param(10:end);
                              end
                           else
                              error('IRISFETCH:Trace:unrecognizedParameter',...
                                 'The text you included as an optional parameter did not parse to either ''INCLUDEPZ'' or ''VERBOSE'' or a service base URL');
                           end
                     end
                  otherwise
                     error('IRISFETCH:Trace:unrecognizedParameter',...
                        'The optional parameter wasn''t recognized. %s', class(param));
               end
            end
            if opts.verbosity
               disp({'spz:',opts.getsacpz,'vb:',opts.verbosity,...
               'auth:',opts.authorize,'qual:',opts.quality,...
               'un&pw:',opts.username,repmat('*',size(opts.userpwd))});
            end
         end % extractAdditionalArguments

         function ts = getTheTraces(N, S, L, C, startDateStr, endDateStr, opts)
            traces=[];
            startDateStr = irisFetch.makeDateStr(startDateStr);
            endDateStr = irisFetch.makeDateStr(endDateStr);
            try
               if opts.authorize
                  dbPrint('traces = tracedata.fetchTraces("%s", "%s", "%s", "%s", "%s", "%s", ''%s'', %d, "%s", "%s")\n',...
                        N, S, L, C, startDateStr, endDateStr, opts.quality, opts.getsacpz, opts.username, repmat('*',size(opts.userpwd)));
                  traces = tracedata.fetchTraces(N, S, L, C, ...
                     startDateStr, endDateStr, opts.quality, opts.getsacpz, opts.username, opts.userpwd);
               else
                  dbPrint('traces = tracedata.fetchTraces("%s", "%s", "%s", "%s", "%s", "%s", ''%s'', %d)\n',...
                        N, S, L, C, startDateStr, endDateStr, opts.quality, opts.getsacpz);
                  traces = tracedata.fetchTraces(N, S, L, C, ...
                     startDateStr, endDateStr, opts.quality, opts.getsacpz); %db removed (;)
               end
               dbPrint('tracedata.fetchTraces successfully completed, resulting in %d traces before converting\n', numel(traces));
            catch je
               % Debug messages:
               dbPrint('An [%s] exception occurred in irisFetch.getTheTraces() but was caught\n full text follows:\nmessage:\n%s\n\n', je.identifier,je.message) %db
               %disp(je.cause); %db
               %disp(je.stack); %db

               switch je.identifier
                  case 'MATLAB:Java:GenericException'
                     if any(strfind(je.message,'URLNotFoundException'))
                        error('IRISFETCH:Trace:URLNotFoundException',...
                           'Trace found no requested data and returned the following error:\n%s',...
                           je.message);
                     end
                     if any(strfind(je.message,'java.io.IOException: edu.iris.dmc.service.UnauthorizedAccessException'))
                         error('IRISFETCH:Trace:UnauthorizedAccessException',...
                             'Invalid Username and Password combination\n');
                     end
                     if any(strfind(je.message,'parseMetadata'))
                         error('IRISFETCH:Trace:Metadata',...
                             'Incomplete metadata detected. Please contact ws-issues@iris.washington.edu with details about your request\n');
                     end
                     if any(strfind(je.message,'NoDataFoundException'))
                         if opts.verbosity
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

            if opts.saveSAC
               irisFetch.write_sac_out(opts.writeDirectory, traces, opts.verbosity);
            end

            if opts.convertToMatlab
               ts = irisFetch.convertTraces(traces);
            else
               ts = traces;
               % warning('in-house experimental: returning the java traces instead of a matlab struct.');
            end
            clear traces

         end %function getTheTraces
         function opts = setOptions(args)
            opts.getsacpz    = false;
            opts.verbosity   = false;
            opts.authorize   = false;
            opts.quality     = 'M';
            opts.username    = '';
            opts.userpwd     = '';
            opts.newbase     = '';
            opts.dataselectURL = '';
            opts.stationURL  = '';
            opts.useFederator = false;
            opts.writeDirectory = '';
            opts.convertToMatlab = true;
            opts.saveSAC = false;
            opts = getUserOptions(opts, args);
         end
      end % Traces

      %% STATION related STATIC, PUBLIC routines
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
         %  PARAMETER LIST
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

      %% EVENT related STATIC, PUBLIC routines
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
         %PARAMETER LIST (for IRIS-WS-2.0.x.jar)
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

         if ~exist('criteria.EventCriteria','class')
            irisFetch.connectToJar()
         end

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
      end


      %% RESPONSE related STATIC, PUBLIC routines
      function [respstructures, urlparams] = Resp(network, station, location, channel, starttime, endtime)
         %irisFetch.Resp retrieves instrument response information
         %
         % re = irisFetch.Resp(network, station, location, channel, startDate, endDate)
         %   will return instrument response information as a character string.
         % 
         % [re, myUrlParams] = irisFetch.Resp(...) will return the URL parameters used to
         %   make the query.
         %
         % The output will be formatted identically to the output provided by the irisws-resp
         %   web service. http://service.iris.edu/irisws/resp/1/
         %
         % channels and locations may be wildcarded using either ? or *
         % startDate and endDate parameters may be specified by closed brackets [] instead of a time.
         
         import edu.iris.dmc.*

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

      %% HELPER ROUTINES

      function connectToJar(isSilent)
         %irisFetch.connectToJar connects to the jar for this MATLAB session
         %  irisFetch.connectToJar() searches the javaclasspath for the
         %  IRIS-WS jar file. If it does not exist, then it will try to access the latest
         %  jar over the internet. If it cannot connect, it will error.
         %
         %  irisFetch requires version 2.0.15 or greater of the IRIS Web Services Library,
         %  available from:
         %
         %  https://ds.iris.edu/files/IRIS-WS/2/IRIS-WS-2.0-latest.jar
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

         if exist('edu.iris.dmc.extensions.fetch.TraceData','class')
            return
         end
         
         % ~~~ IRIS DOWNLOAD ~~~
         if ~isSilent
             disp('Retrieving latest version of IRIS-WS Java library...');
             % DO NOT use https for URL as javaaddpath will not work using
             % https protocol
             latest_jar = 'http://ds.iris.edu/files/IRIS-WS/2/IRIS-WS-2.0-latest.jar';
             javaaddpath(latest_jar);
             if exist('edu.iris.dmc.extensions.fetch.TraceData','class')
                 disp('IRIS-WS java library has been added to your dynamic Java path.');
             else
                disp('Latest version of IRIS-WS Java library cannot be automatically determined.')
                disp('Please download the latest version of the .jar file from this link:')
                disp(latest_jar)
                disp('And add the .jar file to your javaclasspath.');
                disp('  >> javaaddpath(''/usr/local/myworkdir/IRIS-WS.jar'')');
             end
         end
         % ~~~ IRIS DOWNLOAD ~~~    
         
         %   ~~~ GITHUB DOWNLOAD ~~~
         % For automatically downloading library from GitHub
%          if ~isSilent
%              xml = evalc('!curl -L https://github.com/iris-edu/mseedindex/releases/latest');
%              % xml = evalc('!curl -L https://github.com/iris-edu/iris-ws/releases/latest');
%              ver_pat = '>v\d.\d<';
% %              ver_pat = '>\d\.\d\.\d<';  % regexp for a version number triad
%              ver_str = unique(regexp(xml,ver_pat,'match'));
%              if numel(ver_str)==1
%                  ver_str = char(strip(ver_str,'<'));
%                  ver_str = strip(ver_str,'>');
%                  github_base = 'https://github.com/iris-edu/iris-ws/releases/download/';
%                  latest_jar = [github_base ver_str '/IRIS-WS-' ver_str '.jar'];
%                  disp('Acquiring latest version of IRIS-WS Java library:')
%                  disp(latest_jar)
%                  javaaddpath(latest_jar);
%              else
%                  disp('Latest version of IRIS-WS Java library cannot be automatically determined.')
%                  disp('Please download the latest version of the .jar file from this link:')
%                  disp('  https://github.com/iris-edu/iris-ws/releases/latest');
%                  disp('And add the .jar file to your javaclasspath.');
%                  disp('  >> javaaddpath(''/usr/local/myworkdir/IRIS-WS.jar'')');
%              end
%          end
        %   ~~~ GITHUB DOWNLOAD ~~~
         
         if ~exist('edu.iris.dmc.extensions.fetch.TraceData','class')
            error('irisFetch:noDefaultJar',...
               'Unable to access the default jar.  Please download and add the latest version of IRIS-WS library to your javaclasspath.');
         end
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

         if isempty(networkTree)
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

         for n=1:numel(fieldsattop)
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

         for n=1:numel(fieldsattop)
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

               [s,~]=urlread('http://service.iris.edu/irisws/resp/1/query','get', parampairs);

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
            crit          = criteria.RespCriteria();
            crit.setEndTime(javadateTime);
            reconvertedMatlabTime = ...
               datestr(irisFetch.jdate2mdate(javadateTime),irisFetch.DATE_FORMATTER);
            %urlString         = char(criteria.toUrlParams().get(0));
            urlString         = crit.toUrlParams().get(0).toCharArray()';
            if ~(all(reconvertedMatlabTime == matlabTimeString))
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

         blankTrace = struct('network','','station','','location','',...
            'channel','','quality','','latitude',0,'longitude',0,...
            'elevation',0,'depth',0,'azimuth',0,'dip',0,...
            'sensitivity',0,'sensitivityFrequency',0,...
            'instrument','','sensitivityUnits','UNK',...
            'data',[],'sampleCount',0,'sampleRate',nan,...
            'startTime',0,'endTime',0,'sacpz',blankSacPZ);
         mts=blankTrace;
         if isempty(traces)
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


      %{
        ----------------------------------------------------------------
       DATE conversion routines

       Java classes that can be used:
           java.sql.Timestamp : handles nanoseconds
           java.util.Date     : handles milliseconds

       MATLAB is accurate to 0.01 milliseconds
      ----------------------------------------------------------------
      %}

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


      %================================================================
      %----------------------------------------------------------------
      %% PARSING ROUTINES
      %----------------------------------------------------------------
      %================================================================

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
               [x,~] = dbstack(1); %remove this call from the stack, and get the list
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
                  'edu.iris.dmc.fdsn.station.model.Coefficient'
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
               s.Value                   = str2double(value.getValue());
               s.Frequency               = str2double(value.getFrequency());
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
               error('did not expect to get here');
               s.Comment = irisFetch.parseAnArray(value.getComment());
               s.Code                    = char(value.getCode());
               s.Description             = char(value.getDescription());
               s.StartDate               = irisFetch.jdate2mdate(value.getStartDate());
               s.EndDate                 = irisFetch.jdate2mdate(value.getEndDate());
               s.DataAvailability        = irisFetch.parse(value.getDataAvailability()); % get edu.iris.dmc.fdsn.station.model.DataAvailability
               s.RestrictedStatus        = char(value.getRestrictedStatus());
               s.AlternateCode           = char(value.getAlternateCode());
               s.HistoricalCode          = char(value.getHistoricalCode());

            case {'edu.iris.dmc.fdsn.station.model.Channel'}
               s.ChannelCode             = char(value.getCode());
               s.LocationCode            = char(value.getLocationCode());
               s.Description             = char(value.getDescription());
               s.Type                    = char(value.getType());
               
               % Retrieve instrument sensitivity. These values are the INPUT units
               s.Response                = irisFetch.parse(value.getResponse());    % get edu.iris.dmc.fdsn.station.model.Response
               if isempty(s.Response)
                  s.SensitivityFrequency = NaN;
                  s.SensitivityUnitDescription = '';
                  s.SensitivityUnits = '';
                  s.SensitivityValue = NaN;
               elseif isstruct(s.Response.InstrumentSensitivity)
                  s.SensitivityFrequency= s.Response.InstrumentSensitivity.Frequency;
                  s.SensitivityUnitDescription = s.Response.InstrumentSensitivity.InputUnits{2};
                  s.SensitivityUnits = s.Response.InstrumentSensitivity.InputUnits{1};
                  s.SensitivityValue = s.Response.InstrumentSensitivity.Value;
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
               s.StartDate               = irisFetch.jdate2mdate(value.getStartDate());% duplicates StartTime ( but using org.apache.xerces.jaxp.datatype.XMLGregorianCalendarImpl)
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
               s.StartDate               = irisFetch.jdate2mdate(value.getStartDate());
               s.EndDate                 = irisFetch.jdate2mdate(value.getEndDate());
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
               s.StartDate               = irisFetch.jdate2mdate(value.getStartDate());
               s.EndDate                 = irisFetch.jdate2mdate(value.getEndDate());
               s.TotalNumberStations     = double(value.getTotalNumberStations());
               s.SelectedNumberStations  = double(value.getSelectedNumberStations());
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
               warning('IRISFETCH:parse:classNotFound','%s was not found',myClass)
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
         if isnumeric(theArray)
            s = theArray;
            return
         end

         arraySize = theArray.size();
         if arraySize == 0
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
      %% CRITERIA protected routines

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
            [param, value] = deal(paramList{1:2});
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

      %% SAC Read/Write routines

      function [ tr_out ] = read_sac_in(fileDirectory)

         % Determine if the user input is for a file or a whole directory
         % 'exist' returns 2 for files, 7 for directories.
         if exist(fileDirectory,'file')==2  % For a file..
             fileNames = dir(fileDirectory);
         elseif exist(fileDirectory,'dir')==7  % ..for directories..
             if strcmp(fileDirectory,'.')  % ..for 'this' directory..
                 fileDirectory = pwd;
             end
             cd(fileDirectory)
             fileNames = dir('*.SAC');
         elseif  logical(strfind(fileDirectory,'*')) | ~isempty(strfind(fileDirectory,'?')) % ..for wildcards..
             if strcmpi(fileDirectory,'*.SAC')
                 fileNames = dir(fileDirectory);
             else
                 fileNames = dir([fileDirectory '*.SAC']);
             end
         else
             error(['IRISFETCH:read_sac_in - ' fileDirectory ' not a valid file or directory'])
         end

         % SAC header definition
         function sac = make_sac_header(hdrval_n,hdrval_s)

             names = {'DELTA' 'DEPMIN' 'DEPMAX' 'SCALE' 'ODELTA'...
             'B' 'E' 'O' 'A' 'INTERNAL9'...
             'T0' 'T1' 'T2' 'T3' 'T4'...
             'T5' 'T6' 'T7' 'T8' 'T9'...
             'F' 'RESP0' 'RESP1' 'RESP2' 'RESP3'...
             'RESP4' 'RESP5' 'RESP6' 'RESP7' 'RESP8'...
             'RESP9' 'STLA' 'STLO' 'STEL' 'STDP'...
             'EVLA'  'EVLO' 'EVEL' 'EVDP' 'MAG'...
             'USER0' 'USER1' 'USER2' 'USER3' 'USER4'...
             'USER5' 'USER6' 'USER7' 'USER8' 'USER9'...
             'DIST' 'AZ' 'BAZ' 'GCARC' 'INTERNAL54'...
             'INTERNAL55' 'DEPMEN' 'CMPAZ' 'CMPINC' 'XMINIMUM'...
             'XMAXIMUM' 'YMINIMUM' 'YMAXIMUM' 'UNUSED00' 'UNUSED01'...
             'UNUSED02' 'UNUSED03' 'UNUSED04' 'UNUSED05' 'UNUSED06'...
             'NZYEAR' 'NZJDAY' 'NZHOUR' 'NZMIN' 'NZSEC'...
             'NZMSEC' 'NVHDR' 'NORID' 'NEVID' 'NPTS'...
             'INTERNAL80' 'NWFID' 'NXSIZE' 'NYSIZE' 'UNUSED07'...
             'IFTYPE' 'IDEP' 'IZTYPE' 'UNUSED' 'IINST'...
             'ISTREG' 'IEVREG' 'IEVTYP' 'IQUAL' 'ISYNTH'...
             'IMAGTYP' 'IMAGSRC' 'UNUSED08' 'UNUSED09' 'UNUSED10'...
             'UNUSED11' 'UNUSED12' 'UNUSED13' 'UNUSED14' 'UNUSED15'...
             'LEVEN' 'LPSPOL' 'LOVROK' 'LCALDA' 'UNUSED16'...
             'KSTNM' 'KEVNM0' 'KEVNM1'...
             'KHOLE' 'KO' 'KA'...
             'KT0' 'KT1' 'KT2'...
             'KT3' 'KT4' 'KT5'...
             'KT6' 'KT7' 'KT8'...
             'KT9' 'KF' 'KUSER0'...
             'KUSER1' 'KUSER2' 'KCMPNM'...
             'KNETWK' 'KDATRD' 'KINST'};

             if numel(names)~=numel(hdrval_n)+numel(hdrval_s)
                 error('IRISFETCH:read_sac_in - header is not proper length')
             end
             % Read in numeric data..
             for j = 1:length(hdrval_n)
                 sac.(names{j}) = hdrval_n(j);
             end
             % Read in string data.
             for j = 1:length(hdrval_s)
                 % This will store all string values in a cell array, NOT
                 % formatted strings
                 sac.(names{length(hdrval_n)+j}) = hdrval_s{j};
             end
             % Check for empty location header.
             if logical(strfind(sac.KHOLE,'-12345'))
                 sac.KHOLE='';
             end
         end  % END make_sac_header

         blanksacPZ = struct('units',[],'constant',[],'poles',[],'zeros',[]);
         tr_out = repmat(struct('network',[],'station',[],'location',[],...
             'channel',[],'quality',[],'latitude',[],'longitude',[],...
             'elevation',[],'depth',[],'azimuth',[],'dip',[],...
             'sensitivity',[],'sensitivityFrequency',[],'instrument','',...
             'sensitivityUnits',[],'data',[],'sampleCount',[],'sampleRate',[],...
             'startTime',[],'endTime',[],'sacpz',blanksacPZ),numel(fileNames),1);

          function trace_out = format_blank_fields(trace_in)
             % Determines if the fields of a given Trace structure contain
             %   default SAC values and formats them as NaN for numeric fields
             %   and empty arrays for alpha-numeric fields.

             names = fieldnames(trace_in);
             for ii = 1:numel(names)
                 if isnumeric(trace_in.(names{ii})) & trace_in.(names{ii})==-12345
                     trace_in.(names{ii}) = [];
                 elseif ischar(trace_in.(names{ii})) & ~isempty(strfind(trace_in.(names{ii}),'-12345'))
                     trace_in.(names{ii}) = [];
                 end
             end
             trace_out = trace_in;
          end

         % Loop over filenames
         for i=1:numel(fileNames)
             % Assumes little-endian formatting at first, but tries
             % big-endian format below if header values are incorrect.
             % (the test is NVHDR~=6)
             fid = fopen(fileNames(i).name,'r','ieee-le');
             if fid==-1
                 error(['IRISFETCH:read_sac_in - Cannot open file: ' fileNames(i).name])
             end

             % Check SAC header and try byte order
             hn = [fread(fid,[5,14],'float32'),fread(fid,[5,8],'int32')]; hn = hn(:);
             hs = cellstr(fread(fid,[8,24],'*char')');
             hd = fread(fid,'float32');

             if (hn(77) == 4 || hn(77) == 5)
                 fclose(fid);
                 error(['IRISFETCH:read_sac_in - NVHDR = 4 or 5. File: ' fileNames(i).name ...
                     ' may be an old version of SAC'])
             elseif hn(77) ~= 6
                 fclose(fid);
                 fid = fopen(fileNames(i).name,'r','ieee-be');
                 if fid==-1
                     error(['IRISFETCH:read_sac_in - Cannot open file: ' fileNames(i).name])
                 end
                 % Re-read SAC header after retrying byte order
                 hn = [fread(fid,[5,14],'float32'),fread(fid,[5,8],'int32')]; hn = hn(:);
                 hs = cellstr(fread(fid,[8,24],'*char')');
                 hd = fread(fid,'float32');
                 fclose(fid);
             end

             % Match up the header name with its value
             sac = make_sac_header(hn,hs);
             if sac.LEVEN~=1
                 error('IRISFETCH:read_sac_in - Data is unevenly spaced.')
             else
                % Now, match up the header values with what goes into
                % Traces structures.
                date_str = [num2str(sac.NZYEAR) '-' num2str(sac.NZJDAY)...
                    '-' num2str(sac.NZHOUR) ':' num2str(sac.NZMIN)...
                    ':' num2str(sac.NZSEC) '.' num2str(sac.NZMSEC)];
                tr_out(i).network       = sac.KNETWK;
                tr_out(i).station       = sac.KSTNM;
                tr_out(i).location      = sac.KHOLE;
                tr_out(i).channel       = sac.KCMPNM;
                tr_out(i).quality       = [];  % No SAC equivalent
                tr_out(i).latitude      = sac.STLA;
                tr_out(i).longitude     = sac.STLO;
                tr_out(i).elevation     = sac.STEL;
                tr_out(i).depth         = sac.STDP;
                tr_out(i).azimuth       = sac.CMPAZ;
                tr_out(i).dip           = sac.CMPINC;
                tr_out(i).sensitivity   = [];  % No SAC equivalent
                tr_out(i).sensitivityFrequency  = [];  % No SAC equivalent
                tr_out(i).instrument    = sac.KINST;
                tr_out(i).sensitivityUnits      = [];  % No SAC equivalent
                tr_out(i).data =        hd;
                tr_out(i).sampleCount = sac.NPTS;
                tr_out(i).sampleRate =  1/sac.DELTA;
                tr_out(i).startTime =   datenum(date_str,'yyyy-dd-HH:MM:SS.FFF');
                tr_out(i).endTime =     tr_out(i).startTime + sac.NPTS*sac.DELTA/86400;
                tr_out(i).sacpz =       tr_out(i).sacpz;
                tr_out(i) = format_blank_fields(tr_out(i));
             end
         end
      end

      function [ output_args ] = write_sac_out(writeDirectory, traces, verbosity)
         %WRITE_JAVATRACES_TO_SAC Summary of this function goes here
         %   Detailed explanation goes here
         %
         % -- SYNTHETIC TRACES --
         % This function sets the ISYNTH flag to true based on the criteria
         % from: ds.iris.edu/dms/products/shakemoviesynsthetics/
         % That is... if net==SY and either:
         %   * net == SY & loc == S1 & channel in {LXE, LXN, LXZ}
         %   * net == SY & loc == S2 & channel in {MXE, MXN, MXZ}
         %   This behavior is controlled by SET_SYNTHETIC_FLAG

         output_args = true;
         dbPrint = irisFetch.getDBfprintf(verbosity);

         SET_SYNTHETIC_FLAG = true; % set the synthetic flag based on network/channel combo
         for n = 1 : length(traces)
            write_trace(writeDirectory, traces(n))
         end

         function value = adjust_length(value, desired_length)
            % pads character fields with with spaces or crops

            if length(value) < desired_length
               z = '                '; % 16 byte spaces
               value = [value, z(length(value)+1:desired_length)];
            elseif length(value) > desired_length
               value = value(1:desired_length);
            end
         end

         function write_sac_data_values(fid, javaTrace)
            % Write out the amplitude values to the sac file.
            fseek(fid, 0,'eof'); %go to end of file, which should just be the header.
            if isjava(javaTrace)
               data = javaTrace.getAsFloat(); % might be get as Double
               fwrite(fid, data, 'single');
               write_sac_field(fid, 'NPTS', numel(data)); % number of data points
               write_sac_field(fid, 'DEPMIN', min(data)); % min value of data
               write_sac_field(fid, 'DEPMAX', max(data)); % max value of data
               write_sac_field(fid, 'DEPMEN', mean(data)); % eman value of data
            elseif isstruct(javaTrace)
               fwrite(fid, javaTrace.data, 'single');
               write_sac_field(fid, 'NPTS', numel(javaTrace.data)); % number of data points
               write_sac_field(fid, 'DEPMIN', min(javaTrace.data)); % min value of data
               write_sac_field(fid, 'DEPMAX', max(javaTrace.data)); % max value of data
               write_sac_field(fid, 'DEPMEN', mean(javaTrace.data)); % eman value of data
            else
               % unrecognized format
               error('IRISFETCH:traceNeitherJavaNorStruct',...
                  'attempted to interpret data from a trace that was neither a struct nor a java object')
            end

         end

         function write_trace_header_to_sac(fid, javaTrace)
            % write_trace_header_to_sac
            % write header information to file.
            % eg. Net, Sta, Cha, Loc, Lat, Lon, Elev, Depth, Az, Inc,
            %     instName, dates, and delta
            % expects an individual javaTrace or Struct

            % enumerated types...
            ITIME = 1; % time series data
            % data quality descriptions
            % IOTHER = 44;
            % IGOOD = 45;
            % IGLCH = 46;
            % IDROP = 47;

            write_sac_field(fid, 'NVHDR', 6); % sac version

            if isjava(javaTrace)
               % parse out the JAVA object
               write_sac_field(fid, 'KNETWK', char(javaTrace.getNetwork()));
               write_sac_field(fid, 'KSTNM', char(javaTrace.getStation()));
               write_sac_field(fid, 'KHOLE', char(javaTrace.getLocation()));
               write_sac_field(fid, 'KCMPNM', char(javaTrace.getChannel()));

               write_sac_field(fid, 'STLA', javaTrace.getLatitude()); % Station Latitude
               write_sac_field(fid, 'STLO', javaTrace.getLongitude()); % Station Longitude
               write_sac_field(fid, 'STEL', javaTrace.getElevation()); % Station Elevation
               write_sac_field(fid, 'STDP', javaTrace.getDepth()); % Station depth
               write_sac_field(fid, 'CMPAZ', javaTrace.getAzimuth()); % Comp Az (CLK from N)
               write_sac_field(fid, 'CMPINC', javaTrace.getDip() ); % Comp Inc Angle (from vert)

               write_sac_field(fid, 'KINST', char(javaTrace.getInstrument())); % Instrument Name
               % write_sac_field(fid, 'B', javaTrace.getStartTime.getTime); % beginning time (epoch)
               write_sac_field(fid, 'B', 0); % beginning time (epoch)
               %write_sac_field(fid, 'E',); % end time (epoch)
               startTime = javaTrace.getStartTime();
               write_sac_field(fid, 'NZYEAR', startTime.getYear() + 1900); % GMT Year
               write_sac_field(fid, 'NZJDAY', irisFetch.day_of_year(startTime)) % GMT Julian Day of Year
               write_sac_field(fid, 'NZHOUR', startTime.getHours());
               write_sac_field(fid, 'NZMIN', startTime.getMinutes());
               write_sac_field(fid, 'NZSEC', startTime.getSeconds());
               write_sac_field(fid, 'NZMSEC', startTime.getNanos() / 1000000); % 1 mSec = 1e+6 nanoseconds
               write_sac_field(fid, 'IFTYPE', ITIME);

               write_sac_field(fid, 'LEVEN', true); % evenly spaced data
               write_sac_field(fid, 'DELTA', 1/javaTrace.getSampleRate()); % ODELTA would have observed change...
               if SET_SYNTHETIC_FLAG
                  write_sac_field(fid, 'ISYNTH', ...
                     isSynth(char(javaTrace.getNetwork()), ...
                     char(javaTrace.getStation()),...
                     char(javaTrace.getLocation()), ...
                     char(javaTrace.getChannel())))
               end

            elseif isstruct(javaTrace)
               % parse out the TRACE structure.
               write_sac_field(fid, 'KNETWK', javaTrace.network);
               write_sac_field(fid, 'KSTNM', javaTrace.station);
               write_sac_field(fid, 'KHOLE', javaTrace.location);
               write_sac_field(fid, 'KCMPNM', javaTrace.channel);

               write_sac_field(fid, 'STLA', javaTrace.latitude); % Station Latitude
               write_sac_field(fid, 'STLO', javaTrace.longitude); % Station Longitude
               write_sac_field(fid, 'STEL', javaTrace.elevation); % Station Elevation
               write_sac_field(fid, 'STDP', javaTrace.depth); % Station depth
               write_sac_field(fid, 'CMPAZ', javaTrace.azimuth); % Comp Az (CLK from N)
               write_sac_field(fid, 'CMPINC', javaTrace.dip); % Comp Inc Angle (from vert)

               write_sac_field(fid, 'KINST', javaTrace.instrument); % Instrument Name
               % write_sac_field(fid, 'B', javaTrace.getStartTime.getTime); % beginning time (epoch)
               write_sac_field(fid, 'B', 0); % beginning time (epoch)
               %write_sac_field(fid, 'E',); % end time (epoch)
               dv = datevec(javaTrace.startTime);
               write_sac_field(fid, 'NZYEAR', dv(1)); % GMT Year
               write_sac_field(fid, 'NZJDAY', irisFetch.day_of_year(javaTrace.startTime)) % GMT Julian Day of Year
               write_sac_field(fid, 'NZHOUR', dv(4));
               write_sac_field(fid, 'NZMIN', dv(5));
               write_sac_field(fid, 'NZSEC', fix(dv(6)));

               write_sac_field(fid, 'NZMSEC', rem(dv(6),1) * 1000); % 1 mSec = 1e+6 nanoseconds
               write_sac_field(fid, 'IFTYPE', ITIME);

               write_sac_field(fid, 'LEVEN', true); % evenly spaced data
               write_sac_field(fid, 'DELTA', 1/javaTrace.sampleRate); % ODELTA would have observed change...
               if SET_SYNTHETIC_FLAG
                  write_sac_field(fid, 'ISYNTH', ...
                     isSynth(javaTrace.network, ...
                     javaTrace.station, ...
                     javaTrace.location, ...
                     javaTrace.channel));
               end

            else
               % unrecognized format
               error('IRISFETCH:traceNeitherJavaNorStruct',...
                  'attempted to write a trace that was neither a struct nor a java object')
            end

            % ---- KNOWN but IGNORED FIELDS ------------------------------
            % SCALE: since it is not known whether it should be included
            % IQUAL: because SAC quality ~= IRIS quality flags.
            % - Confirmed in issue #579.

            % Described in SAC manual, but not found in the header
            % description: NZDTTM, KZDATE, KZTIME

            % CAN SET LPSPOL from ???
            %write_sac_Field(fid, 'LPSPOL', javaTrace.);
            % station polarity TRUE (+) w/ left hand rule assume TRUE
            % ------------------------------------------------------------


            function isSynthetic = isSynth(net, ~, loc, cha)
               % checks against known synthetic combos.

               % SET ISYNTH ACCORDING TO THE CHANNEL
               % source: ds.iris.edu/dms/products/shakemoviesynsthetics/
               isSynthetic = false;
               if strcmp(net, 'SY')
                  switch loc
                     case 'S1'
                        isSynthetic = ismember(cha,{'LXZ', 'LXN', 'LXE'});
                     case 'S3'
                        isSynthetic = ismember(cha, {'MXZ', 'MXN', 'MXE'});
                     otherwise
                        isSynthetic = false;
                  end
               end
            end
         end

         function write_sac_field(fid, sacfield, value)
            % write_sac_field writes an individual field to the open file.
            % FID is the open file id
            % FIELD is the SAC name of the field
            % VALUE is the value to write to the file
            % The VALUE is written directly to a specific location within
            % the file header, in the pre-determined format.
            thisField = type_details(sacfield);
            switch thisField.outClass
               case 'char'
                  if length(value) ~= thisField.nBytes * 2
                     value = adjust_length(value, thisField.nBytes *2);
                  end
            end
            fieldpos = field_offset(sacfield);
            if ftell(fid) == fieldpos || fseek(fid, fieldpos, 'bof') ~= -1
               %TODO make sure fseek successful!
               fwrite(fid, value, thisField.outClass);
            else
               error('IRISFETCH:sacSeekingProblem',...
                  'problem seeking within the SAC file')
            end
         end

         function write_default_sac_header(fid)
            % writes all header fields to disk, with their default values.
            fseek(fid,0,'bof');
            currpointer = ftell(fid);
            headerDefinition = get_header_definition();
            sacHeaderNames = headerDefinition(:,1);
            for idx = 1 : length(sacHeaderNames)
               sacField = sacHeaderNames{idx};
               if currpointer ~= field_offset(sacField)
                  warning('IRISFETCH:MisplacedFilePointer', ...
                     ['Pointer in wrong position [%d]'...
                     '(expected %d) for field %s'],...
                     currpointer, field_offset(sacField), sacField);
               end
               fieldDetails = type_details(sacField);
               fwrite(fid, fieldDetails.defaultValue, fieldDetails.outClass);
               currpointer = ftell(fid);
            end
         end

         function write_trace(writeDirectory, trace)
            % writes one trace to file with a name based trace's metadata.
            if ~exist(writeDirectory,'dir')
               success = mkdir(writeDirectory);
               if ~success
                  error('irisFetch:Traces:unableToCreateDirectory',...
                     'Write directory does not exist and was unable to be created: [%s]', writeDirectory);
               end
            end
            machineformat = 'ieee-le';
            outputFileName = fullfile(writeDirectory, outputname_from_trace());
            dbPrint('Opening : [%s]\n' , outputFileName)

            fid = fopen(outputFileName, 'w+', machineformat);
            if fid == -1
               error('irisFetch:Traces:unableToWriteFile',...
                  'Unable to write to file: [%s]',outputFileName);
            end
            dbPrint('WRITING TRACE.... to: %s\n', outputFileName)
            dbPrint('  Writing Default Header')
            write_default_sac_header(fid)
            % WRITE SAC FIELDS
            dbPrint('  Modifying with actual values')
            write_trace_header_to_sac(fid, trace)

            % WRITE DATA
            dbPrint('  Writing data values')
            write_sac_data_values(fid, trace)
            dbPrint('  CLOSING')
            fclose(fid);

            function name = outputname_from_trace()
               % ouputname_from_trace returns an automatic name for SACfile
               % output as NETWK.STA.LOC.CHA.JDAY.H.M.S.SAC
               % output as IU.ANMO.00.BHZ.135.23.59.59 (NETWK)

               % matlabdate = datenummx(1970, 1, 1, 0, 0, trace.getStartTime.getTime()/1000);
               formatstring = [...
                  '%s.' ... Network
                  '%s.' ... Station
                  '%s.' ... Location
                  '%s.' ... Channel
                  '%04d.' ... Year
                  '%03d.' ... Julian day
                  '%02d.' ... Hour
                  '%02d.' ... Minute
                  '%02d.' ... Second
                  'SAC'];
               if isjava(trace)
                  name = sprintf(formatstring,...
                     char(trace.getNetwork()), ...
                     char(trace.getStation()), ...
                     char(trace.getLocation()), ...
                     char(trace.getChannel()), ...
                     trace.getStartTime.getYear + 1900,...
                     irisFetch.day_of_year(trace.getStartTime), ...
                     trace.getStartTime.getHours, ...
                     trace.getStartTime.getMinutes, ...
                     trace.getStartTime.getSeconds);
               elseif isstruct(trace)
                  % retrieve trace information from a struct
                  [yr, ~, ~, hr, min, sec] = datevec(trace.startTime);
                  name = sprintf(formatstring,...
                     trace.network, ...
                     trace.station, ...
                     trace.location, ...
                     trace.channel, ...
                     yr,...
                     irisFetch.day_of_year(trace.startTime), ...
                     hr, ...
                     min, ...
                     fix(sec));
               else
                  % unrecognized format
                  error('IRISFETCH:traceNeitherJavaNorStruct',...
                     'attempted to write a trace that was neither a struct nor a java object')
               end
            end
         end

         function typeDetail = type_details(sacField)
            % retrieve details about the requested SAC field in a structure
            % that is defined in get_header_definition()
            persistent allTypeDetails

            if isempty(allTypeDetails)
               allTypeDetails = containers.Map('KeyType', 'char', 'ValueType', 'any');
               headerDefinition = get_header_definition();
               for x = 1 : length(headerDefinition)
                  fieldDef = headerDefinition(x,:);
                  sacName = fieldDef{1};
                  typeDetails = fieldDef{3};
                  allTypeDetails(sacName) = typeDetails;
               end
            end
            typeDetail = allTypeDetails(sacField);
         end

         function offsetInBytes = field_offset(sacField)
            % get offset (in bytes) for a given SAC field name.

            persistent offset

            if isempty(offset)
               % this only runs once per session.
               nBytesPerWord = 4;
               headerDefinition = get_header_definition();
               offset = containers.Map('KeyType', 'char', 'ValueType', 'int32');
               for x = 1 : length(headerDefinition)
                  fieldDef = headerDefinition(x,:);
                  sacName = fieldDef{1};
                  wordOffset = fieldDef{2};
                  offset(sacName) = nBytesPerWord * wordOffset;
               end
            end
            offsetInBytes = offset(sacField);
         end

         function headerDefinition = get_header_definition()
            % get_header_definition returns a cell of {name, word, type; ... }
            %
            % NAME is the SAC name.  Modified, so that UNUSED becomes UNUSED01, etc.
            % WORD is the offset within the file, where 1 word == 4 bytes)
            % TYPE is a struct containing  fields "outClass", "nBytes", and "defaultValue"
            %    WHERE:
            %       OUTCLASS is the class used to write it out to file
            %       NBYTES is the number of bites the value occupies
            %       DEFAULTVALUE is the default value used when initializing a header

            persistent myHeaderDefinition

            if ~isempty(myHeaderDefinition)
               headerDefinition = myHeaderDefinition;
               return
            end

            % ------- Each struct defines a header field -------
            % F: single precision floating point number
            F.outClass = 'single'; F.nBytes = 4;
            F.defaultValue = single(-12345.0);

            % K8: 8 character field
            K8.outClass = 'char'; K8.nBytes = 4;
            K8.defaultValue = '-12345  ';

            % K16: 16 character field
            K16.outClass = 'char'; K16.nBytes = 8;
            K16.defaultValue = '-12345          ';

            % L: Logical field, but stored as 32byte INT on disk
            L.outClass ='int32'; L.nBytes = 4;
            L.defaultValue = int32(false);

            % I: Enumerated class, stored as a 32byte INT on disk.
            I.outClass = 'int32'; I.nBytes = 4;
            I.defaultValue = int32(-12345);

            % N: a 32 byte INT
            N.outClass = 'int32'; N.nBytes = 4;
            N.defaultValue = int32(-12345);

            %SYMANTICS... Actually for K8 and K16, it's 8 and 16 bytes
            %respectively.
            % ------------------------------------------------------------


            % {field name, offset in words (2 bytes each), data type}
            myHeaderDefinition = {
               'DELTA', 0, F;
               'DEPMIN', 1, F;
               'DEPMAX', 2, F;
               'SCALE', 3, F;
               'ODELTA', 4, F;
               'B', 5, F;
               'E', 6, F;
               'O', 7, F;
               'A', 8, F;
               'INTERNAL9', 9, F;
               'T0', 10, F;
               'T1', 11, F;
               'T2', 12, F;
               'T3', 13, F;
               'T4', 14, F;
               'T5', 15, F;
               'T6', 16, F;
               'T7', 17, F;
               'T8', 18, F;
               'T9', 19, F;
               'F', 20, F;
               'RESP0', 21, F;
               'RESP1', 22, F;
               'RESP2', 23, F;
               'RESP3', 24, F;
               'RESP4', 25, F;
               'RESP5', 26, F;
               'RESP6', 27, F;
               'RESP7', 28, F;
               'RESP8', 29, F;
               'RESP9', 30, F;
               'STLA', 31, F;
               'STLO', 32, F;
               'STEL', 33, F;
               'STDP', 34, F;
               'EVLA', 35, F;
               'EVLO', 36, F;
               'EVEL', 37, F;
               'EVDP', 38, F;
               'MAG', 39, F;
               'USER0', 40, F;
               'USER1', 41, F;
               'USER2', 42, F;
               'USER3', 43, F;
               'USER4', 44, F;
               'USER5', 45, F;
               'USER6', 46, F;
               'USER7', 47, F;
               'USER8', 48, F;
               'USER9', 49, F;
               'DIST', 50, F;
               'AZ', 51, F;
               'BAZ', 52, F;
               'GCARC', 53, F;
               'INTERNAL54', 54, F;
               'INTERNAL55', 55, F;
               'DEPMEN', 56, F;
               'CMPAZ', 57, F;
               'CMPINC', 58, F;
               'XMINIMUM', 59, F;
               'XMAXIMUM', 60, F;
               'YMINIMUM', 61, F;
               'YMAXIMUM', 62, F;
               'UNUSED63', 63, F;
               'UNUSED64', 64, F;
               'UNUSED65', 65, F;
               'UNUSED66', 66, F;
               'UNUSED67', 67, F;
               'UNUSED68', 68, F;
               'UNUSED69', 69, F;
               'NZYEAR', 70, I;
               'NZJDAY', 71, I;
               'NZHOUR', 72, I;
               'NZMIN', 73, I;
               'NZSEC', 74, I;
               'NZMSEC', 75, I;
               'NVHDR', 76, I;
               'NORID', 77, I;
               'NEVID', 78, I;
               'NPTS', 79, I;
               'INTERNAL80', 80, I;
               'NFWID', 81, I;
               'NXSIZE', 82, I;
               'NYSIZE', 83, I;
               'UNUSED84', 84, I;
               'IFTYPE', 85, I;
               'IDEP', 86, I;
               'IZTYPE', 87, I;
               'UNUSED88', 88, I;
               'IINST', 89, I;
               'ISTREG', 90, I;
               'IEVREG', 91, I;
               'IEVTYP', 92, I;
               'IQUAL', 93, I;
               'ISYNTH', 94, I;
               'IMAGTYP', 95, I;
               'IMAGSRC', 96, I;
               'UNUSED97', 97, I;
               'UNUSED98', 98, I;
               'UNUSED99', 99, I;
               'UNUSED100', 100, I;
               'UNUSED101', 101, I;
               'UNUSED102', 102, I;
               'UNUSED103', 103, I;
               'UNUSED104', 104, I;
               'LEVEN', 105, L;
               'LPSPOL', 106, L;
               'LOVROK', 107, L;
               'LCALDA', 108, L;
               'UNUSED109', 109, L;
               'KSTNM', 110, K8;
               'KEVNM', 112, K16;
               'KHOLE', 116, K8;
               'KO', 118, K8;
               'KA', 120, K8;
               'KTO', 122, K8;
               'KT1', 124, K8;
               'KT2', 126, K8;
               'KT3', 128, K8;
               'KT4', 130, K8;
               'KT5', 132, K8;
               'KT6', 134, K8;
               'KT7', 136, K8;
               'KT8', 138, K8;
               'KT9', 140, K8;
               'KF', 142, K8;
               'KUSER0', 144, K8;
               'KUSER1', 146, K8;
               'KUSER2', 148, K8;
               'KCMPNM', 150, K8;
               'KNETWK', 152, K8;
               'KDATRD', 154, K8;
               'KINST', 156, K8;
               };

            headerDefinition = myHeaderDefinition;
         end
      end

      %
      % END SAC Read/Write routines
      %

      function doy = day_of_year(javadate)
         if isjava(javadate)
            mdate = irisFetch.jdate2mdate(javadate);
         else  % already a matlab datenum
            mdate = javadate;
         end
         [y, ~, ~] = datevec(mdate);
         doy = fix(datenum(mdate)) - datenum([y - 1, 12, 31, 0, 0, 0]);
      end

      function f = getDBfprintf(verbosity)
         % get a function that conditionally displays messages.
         %   dbPrint = irisFetch.getDBfprintf(verbosity)
         %      where VERBOSITY is true or false
         % then use dbPrint instead of fprintf (to console only!) or disp
         % dbPrint('This is a thing'); % will show this ONLY if verbosity
         % was set to true when dbPrint was retrieved.
         %   dbPrint = irisFetch.getDBfprintf(verbosity)
         if verbosity
            f = @irisFetch.verbosePrint;
         else
            f = @irisFetch.doNothing;
         end
      end

      function doNothing(varargin)
         % this function does nothing.
         % used by irisFetch.getDBfprintf when verbosity is false
      end

      function verbosePrint(varargin)
         % this function replaces fprintf and printf to conditionally
         % print information to the console. used by irisFetch.getDBfprintf
         % when verbosity is true.
         if nargin == 1
            disp(varargin{1})
         else
            fprintf(varargin{:});
         end
      end

   end %static protected methods
end
