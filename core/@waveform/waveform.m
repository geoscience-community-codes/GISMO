function w = waveform(varargin)
%WAVEFORM Waveform Class constructor
%    Create a waveform object. This is mainly used to load waveform data 
%    from different file formats (e.g. MiniSEED, Seisan, SAC) and services
%    (e.g. IRIS webservices, Earthworm/Winston waveserver).
%    
%    The general format is:
%    
%      w = WAVEFORM(ds, chantags, starttime, endtime)
%    
%    or:
%    
%      w = WAVEFORM(ds, scnls, starttime, endtime)
%
%    or if loading a single file, there is this simple way that works for file_format = 'sac', 'seisan', 'seed' or 'miniseed':
%
%      w = WAVEFORM(filepath, file_format)
%    
%    Arguments:
%       ds - a DATASOURCE object. This defines where to get the
%       waveform data from.
%    
%       ctags - an array of ChannelTag objects.
%       These describe the network.station.locations.channel combinations
%       to load data for. E.g. ctags = ChannelTag('AV.REF..EHZ') to get
%       channel 'EHZ' from station 'REF' for network 'AV' (location is
%       blank, hence the ..)
%    
%           or scnlobjects - an array of SCNLOBJECT objects, which
%           describe the station-channel-network-location combinations
%           to load data for 
%               e.g. scnls = scnlobject('REF', 'EHZ', 'AV', '')
%    
%       start_time - the start of the time window to load. Can be a DATENUM
%       e.g. datenum(YYYY,MM,DD,hh,mm,ss), or any date string literal
%       accepted by DATESTR.
%    
%       endtime - the end of the time window to load.
%    
%    Other ways to construct a waveform object:
%    
%     w = WAVEFORM() creates a blank waveform object
%    
%     w = WAVEFORM(ChannelTag, samplerate, starttime, data, units) creates
%         a waveform from consituent parts.
%    
%         CHANNELTAG - either 'net.sta.loc.cha' or a ChannelTag 
%         SAMPLERATE - Sampling frequency, in Hz       (default NaN)
%         DATA - a vector of seismic amplitudes        (default [])
%         STARTTIME - Start time, in most any format   (default '1/1/1970')
%         UNITS - a string describing the data units
%    
%       If the data requested by waveform consists of multiple segments, then
%       these segments will be combined into a single time series, with the 
%       value NaN filling any missing samples. 
%    
%    --------
%    EXAMPLES
%    --------
%    The only thing that varies between loading from IRIS DMC webservices,
%    an Miniseed or SAC file, a WINSTON or Earthworm waveform and an 
%    Antelope database is the datasource(...) command. So the following
%    examples also show some different ways to construct the other
%    arguments - chantags/scnls, startTime & endTime, which will work 
%    regardless of which datasource is used.
%    
%    (1) MiniSEED file:
%    ------------------
%
%	% The old, hard way to load a single MiniSEED file is like this:
%
%       chantag = ChannelTag('AV.PN7A.-.BDF')
%       startTime = datenum(2007,8,28);
%       endTime = startTime + 1; % 1 day later 
%       mseedfile = 'SEEDDATA/PN7A.BDF.2007.240';
%       ds = datasource('miniseed', mseedfile );
%       w=waveform(ds, chantag, startTime, endTime);
%
%       % the easy way is like this:
%
%       mseedfile = 'SEEDDATA/PN7A.BDF.2007.240';
%	w = waveform(mseedfile, 'miniseed')
%
%    
%    (2) SAC file:
%    -------------
%
%	% The old, hard way to load a single SAC file is like this:
%
%       chantag = ChannelTag('AV.PN7A.-.BDF')
%       startTime = datenum(2007,8,28);
%       endTime = startTime + 1; % 1 day later 
%       sacfile = 'SACDATA/PN7A.BDF.2007-08-28T00:00:00.000000Z.sac';
%       ds = datasource('sac', sacfile );
%       w=waveform(ds, chantag, startTime, endTime);

%       % the easy way is like this:
%
%       sacfile = 'SACDATA/PN7A.BDF.2007-08-28T00:00:00.000000Z.sac';
%	w = waveform(sacfile, 'sac')
%    
%    
%    (3) IRIS DMC web services:
%    --------------------------
%       ds = datasource('irisdmcws'); % data_source is IRIS DMC webservices
%       startTime = '2012-03-03 00:00:00';
%       endTime   = '2012-03-03 01:00:00'; % 1 hour later
%       
%       % Get TA pressure sensor stations within a circular region:
%       s = irisFetch.Channels('channel','TA','*','*','BD*', ... 
%           'StartTime', startTime, 'EndTime', endTime, ... 
%           'radialcoordinates',[33.87 -85.30 km2deg(200) 0]);
%       
%       % Make a ChannelTag array of all the net.sta.loc.chan combos:
%       chantags = ChannelTag.array({s.NetworkCode}, {s.StationCode}, ...
%           {s.LocationCode}, {s.ChannelCode});
%    
%       % Create the waveform object (load the data)
%       w = waveform(ds, chantags, startTime, endTime);
%    
%    (4) Antelope database:
%    ----------------------
%    
%       dbpath = '/path/to/my/antelope/database';
%       ds = datasource('antelope', dbpath);
%       startTime = datenum(2009,3,22);
%       endTime = startTime + 1/24; % 1 hour of data
%       % get EHZ channel for stations RSO and REF
%       scnls = scnlobject({'REF';'RSO'},'EHZ'); 
%       w = waveform(ds, scnls, startTime, endTime);
%    
%       % NOTE: You must have the Antelope toolbox installed, since GISMO 
%       uses this to load Antelope databases.
%    
%    (5) WINSTON or Earthworm waveServer:
%    -------------------------------------
%    
%       % This example attempts gets the last 10 minutes of data 
%       % from the AVO public WINSTON server for the EHZ channel at
%       stations REF and RSO.
%    
%         chantags = ChannelTag({'AV.RSO..EHZ','AV.REF..EHZ'});
%         ds = datasource('winston','pubavo1.wr.usgs.gov',16022);
%         w = waveform(ds, chantags, now - 10/1440, now);
%    
%       WARNING: Data received through winston is in COUNTS, and is
%       not adjusted for instrument gain. To fix this, you'll
%       need to scale the data by the correct gain (e.g. in nm/s per count) 
%               Ex: w = w .* instrumentGain
%    
%    
%    see also ChannelTag, datasource, scnlobject, datenum, datestr
%    
%    VERSION: 2.0 of waveform objects
%    AUTHOR: Celso Reyes
%    Help updated by Glenn 02-AUG-2016 to make it easier for users to find
%    examples of modern usage and common data sources
%    
%    considerations when changing the internals:
%     when replacing scnl with ChannelTag, affects loadobj!
   
   global WaveformNamespaceIsLoaded
   if isempty(WaveformNamespaceIsLoaded)
      WaveformNamespaceIsLoaded = loadGlobalNamespace();
   end;
   persistent waveformversion
   if isempty(waveformversion)
      waveformversion = 2.0;
   end
   
   % usage: [optExists, value, vargs] = peel_option(vargs, searchValue, searchClass, minPos)
   [COMBINE_WAVES, ~, varargin] = peel_option(varargin, 'nocombine', 'char', 5);
   [NOEXIT_OPTION, bwkaround, varargin] = peel_option(varargin, [], 'logical', 5);
   
   argCount = numel(varargin);
   
   updateWarningID = 'Waveform:waveform:oldUsage';
   
   switch argCount
      case 0
         w = genericWaveform();
      case 2 
         if isa(varargin{1}, 'char')
            filename = varargin{1}

            % Glenn Thompson 20180703: added to deal with files downloaded from web addresses
            if strfind(filename,'http')
                url=filename;
                filename=strrep(url,'http://','');
                filename=strrep(filename,'https://','');
                filename=strrep(filename,'/','.');
                websave(filename, url);
            end
            if exist(filename,'file')            
                filetype = varargin{2};
                switch lower(filetype)
                    case 'sac',
                        w = load_sac(filename);
                    case {'seed','miniseed'},
                        w = load_miniseed(filename);
                    case 'seisan',
                        w = load_seisan(filename);
                    otherwise
                        warning(sprintf('filetype %s unknown',filetype));
                end
            else
                warning(sprintf('file %s not found',filename));
            end
         else
             warning('filename must be a string');
         end
         
      case 4
         [arg1, arg2, arg3, arg4] = deal(varargin{:});
         switch class(arg1)
            case 'datasource' %datsource, ChannelTag/scnl/text, starttimes, endtimes
               w = waveformFromDatasource(arg1, as_channeltag(arg2), arg3, arg4);
            otherwise % assumed to be Channeltag or something that can be converted into it
               w = waveformFromParts(as_channeltag(arg1), arg2, arg3, arg4, 'Counts');
         end
      case 5
         [arg1, arg2, arg3, arg4, arg5] = deal(varargin{:});
         switch class(arg1)
            case 'datasource' %INPUT(datasource, ChannelTag, starttimes, endtimes)
               error(updateWarningID,'Should never get to this section of code');
            otherwise
               if ischar(arg1) && ischar(arg2) %given station, channel
                  warning(updateWarningID,... % could make this a ERROR instead
                     ['ancient usage.\nInstead of:\n   waveform(''%s'', ''%s'', ...\n',...
                     'use the ''NET.STA.LOC.CHA'' form:\n   waveform(''.%s..%s'', ...\n',...
                     'however, it is recommended that you include network and location info if available'],...
                     arg1, arg2, arg1, arg2);
                  arg1 = ['.' arg1 '..' arg2];
                  [arg2, arg3, arg4, arg5] = deal(arg3, arg4, arg5, 'Counts');
               end
               arg1 = as_channeltag(arg1);
               w = waveformFromParts(arg1, arg2, arg3, arg4, arg5);
         end
         
      case 8
         w = winston_access(varargin{:});
      otherwise
         disp('Invalid arguments in waveform constructor:');
         disp(varargin);
         error('Waveform:waveform:InvalidWaveformArugments',...
            ['Valid ways of calling waveform include: \n',...
            '   w = WAVEFORM()\n',...
            '   w = WAVEFORM(filename, file_format)\n', ...
            '   w = WAVEFORM(datasource, ChannelTag, starttimes, endtimes)\n',...
            '   w = WAVEFORM(ChannelTag, samplefreq, starttime, data, units)\n']);
   end
   
   function w = genericWaveform()
      persistent blankW
      persistent wCreated
      if ~isempty(wCreated)
         w = blankW;
         w.history = {'created', now};
      else
         %create a fresh waveform.  All calls to the waveform object, aside
         %from the "copy" call (case nargin==1) will be initated HERE.
         blankW.cha_tag = ChannelTag();
         blankW.Fs = NaN;
         blankW.start = 719529; % datenum for 1970-01-01
         blankW.data = double([]);
         blankW.units = 'Counts';
         blankW.version = waveformversion; %version of waveform object (internal)
         blankW.misc_fields = {}; %add'l fields, such as "comments", or "trig"
         blankW.misc_values = {}; %values for these fields
         blankW.history = {'created',[]};
         blankW = class(blankW, 'waveform');
         wCreated = true;
         w = blankW;
      end
   end
   
   function w = waveformFromParts(chaTag, freq, starttime, data, units)
      w = genericWaveform();
      w.cha_tag = chaTag;%(DEFAULT_STATION,DEFAULT_CHAN);
      w.Fs = freq;
      w.start = datenum(starttime);
      w.data = double(data(:));
      w.units = units; %units for data (nm? counts?)
      w.version = waveformversion; %version of waveform object (internal)
      w.misc_fields = {}; %add'l fields, such as "comments", or "trig"
      w.misc_values = {}; %values for these fields
   end
   
   function w = waveformFromDatasource(ds, chans, startt, endt)
         startt = ensure_dateformat(startt);
         endt = ensure_dateformat(endt);
         usewkaround = NOEXIT_OPTION && bwkaround;
         w = load_from_datasource(ds, chans, startt, endt, COMBINE_WAVES, usewkaround);
   end
end

function out = ensure_dateformat(t)
   % returns a matrix of datenums of same shape as t
   if isnumeric(t)
      out = t;
   elseif ischar(t),
      for n = size(t,1) : -1 : 1
         out(n) = datenum(t(n,:));
      end
   elseif iscell(t)
      out(:) = datenum(t);
   end
end

