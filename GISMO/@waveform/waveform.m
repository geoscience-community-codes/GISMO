function w = waveform(varargin)
   %WAVEFORM Waveform Class constructor
   %   w = WAVEFORM(datasource, channeltags, starttimes, endtimes)
   %          loads waveform from the specified DATASOURCE
   %          SCNL stands for STATION-CHANNEL-NETWORK-LOCATION.
   %          multiple start-endtime pairs may be used, while station-channel
   %          pairs can be provided as an array of channeltags
   %
   %  w = WAVEFORM() creates a blank waveform
   %
   %  w = WAVEFORM(channeltag, samplerate, starttime, data, units) creates
   %      a waveform from consituent parts.
   %
   %      CHANNELTAG - either 'net.sta.loc.cha' or a channeltag 
   %             (channeltag replaces the old scnlobject)
   %      SAMPLERATE - Sampling frequency, in Hz       (default nan)
   %      DATA - a vector of seismic amplitudes        (default [])
   %      STARTTIME - Start time, in most any format   (default '1/1/1970')
   %      UNITS - a string describing the data units
   %
   %  w = WAVEFORM(...,'nocombine')
   %    If the data requested by waveform consists of multiple segments, then
   %    these segments will be combined, with NaN filling any data gaps. 
   %    'nocombine' overrides this behavior.
   %
   %
   %    ---------- USING WAVEFORM WITH ANTELOPE ------------
   %    The Antelope Toolbox must be installed.
   %    w = WAVEFORM(..., 'noexit') attempts to avoid antelope segfaults
   %
   %    ---------- USING WAVEFORM WITH WINSTON -------------
   %    To use the waveform files with winston, you need to have the usgs.jar
   %    file. If you have already installed SWARM, then this .jar file already
   %    exist in your swarm/lib directory (or thereabouts).
   %
   %    Edit Matlab's classpath.txt file (located in the toolbox/local
   %    directory) and add the location of this .jar files.
   %
   %    WINSTON WARNING: Data received through winston is in COUNTS, and is
   %        not adjusted for instrument gain. To fix this, you'll
   %        need to scale the data by the correct gain.  
   %            Ex: W = W .* instGain
   % 
   %    % WINSTON EXAMPLE: This example gets a few minutes of data 
   %    % (starting a day ago) from a ficticious winston server.  
   %    % Data returned is for the EHZ channel at each of the three 
   %    % selected stations.
   %
   %      tags = channeltag({'AV.OKCF..EHZ','AV.PV6..EHZ','AV.SSLS..EHZ'});
   %      mySource = datasource('winston','servername.here.edu',1255);
   %      w = waveform(mySource, tags, now - 1, now - .98);
   %
   %
   % ------------ DEPRECATED USAGE ---------------
   %   w = WAVEFORM(station, channel, samplerate, starttime, data)
   %
   % see also channeltag, datasource
   
   % VERSION: 2.0 of waveform objects
   % AUTHOR: Celso Reyes
   
   % considerations when changing the internals:
   %  when replacing scnl with channeltag, affects loadobj!
   
   global WaveformNamespaceIsLoaded
   if isempty(WaveformNamespaceIsLoaded)
      WaveformNamespaceIsLoaded = loadGlobalNamespace();
   end;
   persistent waveformversion
   if isempty(waveformversion)
      waveformversion = 2.0;
   end
   
   % usage: [optExists, value, vargs] = peelOption(vargs, searchValue, searchClass, minPos)
   [COMBINE_WAVES, ~, varargin] = peelOption(varargin, 'nocombine', 'char', 5);
   [NOEXIT_OPTION, bwkaround, varargin] = peelOption(varargin, [], 'logical', 5);
   
   argCount = numel(varargin);
   
   updateWarningID = 'Waveform:waveform:oldUsage';
   
   switch argCount
      case 0
         w = genericWaveform();
         
      case 1   %"copy" a waveform object
         anyV = varargin{1};
         if isa(anyV, 'waveform')
            w = anyV;
         end;
         % SHOULD THERE BE A WARNING OTHERWISE?
         
      case 4
         [arg1, arg2, arg3, arg4] = deal(varargin{:});
         switch class(arg1)
            case 'datasource' %datsource, channeltag/scnl/text, starttimes, endtimes
               arg2 = asChanneltag(arg2);
            otherwise
               arg1 = asChanneltag(arg1);
               w = waveformFromParts(arg1, arg2, arg3, arg4, 'Unk');
               return;
         end
         
         % eg.  INPUT: (datasource, channeltags, startTimes, endTimes)
         [ds, chans, startt, endt] = deal(arg1, arg2, arg3, arg4);
         
         startt = ensure_dateformat(startt);
         endt = ensure_dateformat(endt);
         
         % -------------------------------------------------------------------
         % if there is no specifically assigned load function, then
         % determine the load function based upon the datasource's type
         
         if isVoidInterpreter(ds)
            ds_type  = get(ds,'type');
            if strcmp(ds_type,'antelope') && NOEXIT_OPTION && bwkaround
               myLoadRoutine = eval('@load_antelope_workaround');
            else
               myLoadRoutine = eval(['@load_', ds_type]);
            end
            switch lower(ds_type)
               
               % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
               % file, sac, and seisan all do not require fancy handling.  The
               % load routine and interpreter will be set, and the waveform will
               % be loaded in the following section, along with any user-defined
               % load functions.
               case {'file','sac','seisan','obspy'}
                  ds = setinterpreter(ds,myLoadRoutine); %update interpeter funct
                  
                  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                  % database types require fancier handling. load waveforms right here.
               case {'antelope', 'irisdmcws', 'winston'}
                  w = myLoadRoutine( makeDataRequest(ds, chans, startt, endt), COMBINE_WAVES);
               otherwise
                  error('Waveform:waveform:noDatasourceInterpreter',...
                     'user defined datasources should be associated with an interpreter');
            end %switch
         end %isvoidInterpreter
         
         
         % -------------------------------------------------------------------
         % if the datasource is file based, or if it requires a user-defined
         % intepreter function, then do what follows.  Otherwise, we're done
         
         if ~isVoidInterpreter(ds)
            myLoadFunc = get(ds,'interpreter');
            
            %user_defined datasource
            ALLOW_MULTIPLE = true;
            ERROR_ON_EMPTY = true;
            for j = 1:numel(startt)
               myStartTime = startt(j);
               myEndTime = endt(j);
               
               % grab all files for date range, discarding duplicates
               fn = getfilename(ds, chans,subdivide_files_by_date(ds,myStartTime, myEndTime));
               fn = unique(fn);
               
               %load all waveforms for these files
               clear somew
               
               for i=1:numel(fn)
                  w = load_from_file(myLoadFunc,fn{i},ALLOW_MULTIPLE, ERROR_ON_EMPTY);
                  %w = w(ismember([w.cha_tag],[chans])); %keep only appropriate station/chan
                  w = w(w.cha_tag.matching(chans)); %Not 100% sure about this one
                  w = filter_by_time(w, myStartTime, myEndTime);
                  if numel(w) > 0
                     somew(i) = {w};
                  end
               end %for fn
               if ~exist('somew','var')
                  w = waveform; w = w([]);
               else
                  if COMBINE_WAVES,
                     w = combine([somew{:}]);
                  else
                     w = [somew{:}];
                  end
               end
               allw(j) = {w};
            end %each start time
            w = [allw{:}];
         end %~isVoidInterpreter
         
      case 5
         [arg1, arg2, arg3, arg4, arg5] = deal(varargin{:});
         switch class(arg1)
            case 'datasource' %INPUT(datasource, channeltag, starttimes, endtimes)
               error(updateWarningID,'Should never get to this section of code');
            otherwise
               if ischar(arg1) && ischar(arg2) %given station, channel
                  warning('ancient usage');
                  arg1 = ['.' arg1 '..' arg2];
                  [arg2, arg3, arg4, arg5] = deal(arg3, arg4, arg5, 'Unk');
               end
               arg1 = asChanneltag(arg1);
               w = waveformFromParts(arg1, arg2, arg3, arg4, arg5);
               return;
         end
         
      case 8
         w = winstonAccess(varargin{:});
      otherwise
         disp('Invalid arguments in waveform constructor:');
         disp(varargin);
         error('Waveform:waveform:InvalidWaveformArugments',...
            ['Valid ways of calling waveform include: \n',...
            '   w = WAVEFORM()\n',...
            '   w = WAVEFORM(datasource, channeltag, starttimes, endtimes)\n',...
            '   w = WAVEFORM(channeltag, samplefreq, starttime, data, units)\n']);
   end
   function w = genericWaveform()
      %create a fresh waveform.  All calls to the waveform object, aside
      %from the "copy" call (case nargin==1) will be initated HERE.
      w.cha_tag = channeltag();
      w.Fs = nan;
      w.start = 719529; % datenum for 1970-01-01
      w.data = double([]);
      w.units = 'Unk';
      w.version = waveformversion; %version of waveform object (internal)
      w.misc_fields = {}; %add'l fields, such as "comments", or "trig"
      w.misc_values = {}; %values for these fields
      w.history = {'created',now};
      w = class(w, 'waveform');
   end
   function w = waveformFromParts(chaTag, freq, starttime, data, units)
      w.cha_tag = chaTag;%(DEFAULT_STATION,DEFAULT_CHAN);
      w.Fs = freq;
      w.start = datenum(starttime);
      w.data = double(data(:));
      w.units = units; %units for data (nm? counts?)
      w.version = waveformversion; %version of waveform object (internal)
      w.misc_fields = {}; %add'l fields, such as "comments", or "trig"
      w.misc_values = {}; %values for these fields
      w.history = {'created',now};
      w = class(w, 'waveform');
   end
end

function w = filter_by_time(w, myStartTime, myEndTime)
   % subset and consolidate
   [wstarts, wends] = gettimerange(w);
   wavesWithinWindow = wstarts < myEndTime & wends > myStartTime;
   if any(wavesWithinWindow)
      w = extract(w(wavesWithinWindow),'time',myStartTime,myEndTime);
   else
      w(:)=[]; %return an empty waveform
   end
end

function tf = isVoidInterpreter(ds)
   tf = strcmpi(func2str(get(ds,'interpreter')),'void_interpreter');
end

function datarequest = makeDataRequest(ds, chans, st, ed)
   datarequest = struct(...
      'dataSource', ds, ...
      'scnls', chans, ...
      'startTimes', st,...
      'endTimes',ed);
end

function s = updateWarningMessage()
   
   updateMessageBase = ...
      ['Instead, please call the waveform constructor with '...
      ' a datasource and locationtag. \n'...
      'USAGE: w = waveform(datasource, locationtag, starttimes, endtimes)\n'...
      '   ...modifying request and proceeding.'];
   s = sprintf('%s',updateMessageBase);
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
   % previously implemented as:
   % if ischar(startt), startt = {startt}; end
   % if ischar (endt), endt = {endt}; end;
   % startt = reshape(datenum(startt(:)),size(startt));
   % endt = reshape(datenum(endt(:)),size(endt));
end

function w = load_from_file(myLoadFunc, fname, allowMultiple, ErrorOnEmpty)
   % load waveforms from a file using myLoadfunc
   % w = load_from_file(myLoadFunc, singleFileName);
   %     singleFileName may have wildcards.
   
   
   possiblefiles = dir(fname); % this handles wildcards
   
   if isempty(possiblefiles)
      error('Waveform:waveform:FileNotFound','No file matches: %s', fname);
   end
   
   mydir = fileparts(fname); %fileparts returns [path, name, ext]
   myfiles = fullfile(mydir, {possiblefiles(:).name});
   w(numel(myfiles)) = waveform; %best-guess preinitialization (candidate for trouble!)
   startindex = 0;
   while ~isempty(myfiles)
      [f, myfiles] = peel(myfiles);
      tmp = myLoadFunc(f);
      nFound = numel(tmp);
      switch nFound
         case 0
            if ErrorOnEmpty
               error('Waveform:waveform:noData','no data retrieved: %s', f);
            end
         case 1
            w(startindex+1) = tmp;
         otherwise
            if allowMultiple
               w(startindex+1:startindex+nFound) = tmp(:);
            else
               error('Waveform:waveform:MultipleWaveformsInFile',...
                  'Expected a single waveform, but several exist: %s', f)
            end
      end %switch
      startindex = startindex + nFound;
   end %while
end %load_from_file

function [v, cell_array] = peel(cell_array)
   % remove first item from a cell array, return remaining items
   v = cell_array{1};
   cell_array(1) = [];
end %peel

function [optExists, value, vargs] = peelOption(vargs, searchValue, searchClass, minPos)
   optExists = false; value = [];
   if minPos > numel(vargs)
      return
   end
   switch searchClass
      case 'char'
         for n = minPos:numel(vargs)
            if ischar(vargs{n})
               if isempty(searchValue) || strcmp(searchValue,vargs{n})
                  optExists = true; value = vargs{n}; vargs(n) = [];
                  return
               end
            end
         end
      otherwise
         for n = minPos: numel(vargs)
            if isa(vargs{n},searchClass)
               if isempty(searchValue) || vargs{n} == searchValue
                  optExists = true; value = vargs{n}; vargs(n) = [];
                  return
               end
            end
         end
   end
end

function w = winstonAccess(varargin)
   DEFAULT_CHAN = 'EHZ';
   DEFAULT_STATION = 'UNK';
   DEFAULT_START = datenum([1970 1 1 0 0 0]);
   DEFAULT_END = DEFAULT_START + datenum([0,0,0,0,5,0]); %five minutes
   
   % the following are for WINSTON access...
   DEFAULT_NETWORK = '';
   DEFAULT_LOCATION = '';
   DEFAULT_SERVER = 'churchill.giseis.alaska.edu';
   DEFAULT_PORT = 16022;
   warning(updateWarningID,updateWarningMessage);
   
   % INPUT: waveform (station, channel, start, end, network,
   %                  location, server, port)
   MyDefaults = {DEFAULT_STATION, DEFAULT_CHAN, DEFAULT_START, ...
      DEFAULT_END, DEFAULT_NETWORK, DEFAULT_LOCATION,...
      DEFAULT_SERVER, DEFAULT_PORT}; %#ok<NASGU>
   
   MyVars = {'station', 'channel', 'Tstart', 'Tend', 'netwk', ...
      'location', 'server', 'port'};
   
   %Fill in all the variables with the appropriate default values
   for N = 1:argCount
      if isempty(varargin{N}),
         eval([MyVars{N},' = MyDefaults{N};'])
      else
         eval([MyVars{N},' = varargin{N};'])
      end
   end
   thesechans = channeltag(station,channel,netwk,location);
   
   mydatasource = datasource('winston',server,port);
   w = waveform(mydatasource,thesechans,datenum(Tstart),datenum(Tend));
end

function obj = asChanneltag(obj)
   switch(class(obj))
      case 'channeltag' %good. do nothing.
      case 'scnlobject'
         obj = get(obj, 'channeltag');
      otherwise
         obj = channeltag(obj); %attempt natural conversion
         % should be able to handle 'N.S.L.C'
   end
end
