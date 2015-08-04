function w = waveform(varargin)
   %WAVEFORM Waveform Class constructor
   %   w = WAVEFORM(datasource, channeltags, starttimes, endtimes)
   %          loads waveform from the specified DATASOURCE
   %          SCNL stands for STATION-CHANNEL-NETWORK-LOCATION.
   %          multiple start-endtime pairs may be used, while station-channel
   %          pairs can be provided as an array of channeltags
   %
   %   w = WAVEFORM() creates a blank waveform
   %
   %  w = WAVEFORM(channeltag, samplerate, starttime, data, units)
   %
   %      CHANNELTAG - can be either a net.sta.loc.cha text representation
   %      e.g. 'IU.ANMO.00.BHZ'
   %      or a channeltag object
   %      e.g. channeltag('IU','ANMO','00','BHZ')
   %
   %      SAMPLERATE - Sampling frequency, in Hz       (default nan)
   %      DATA - a vector of seismic amplitudes        (default [])
   %      STARTTIME - Start time, in most any format   (default '1/1/1970')
   %
   %
   %  w = WAVEFORM(...,'nocombine')
   %    If the data requested by waveform consists of multiple segments, then
   %    these segments will be combined, with NaN filling any data gaps.  Set
   %    the last argument to 'nocombine' to override this behavior.  Be aware
   %    that with the nocombine option, the returned value may include
   %    multiple waveforms for each starttime-endtime combination.
   %  w = WAVEFORM(..., 'noexit')
   %  w = WAVEFORM(..., 'alternate database');
   %
   %    ---------- USING WAVEFORM WITH ANTELOPE ------------
   %    The Antelope Toolbox must be installed.
   %
   %    ---------- USING WAVEFORM WITH WINSTON -------------
   %    To use the waveform files with winston, you need to have the usgs.jar
   %    file. If you have already installed SWARM, then this .jar file already
   %    exist in your swarm/lib directory (or thereabouts).
   %
   %    Edit Matlab's classpath.txt file (located in the toolbox/local
   %    directory) and add the location of this .jar files.
   %
   %    WINSTON WARNING: Currently, data received through winston is not adjusted
   %    for instrument gain, therefore, it is in COUNTS.  To fix this, you'll
   %    need to multiply it by the correct gain.  Ex.  W = W .* 6.67;  This
   %    merely scales the data...
   %
   %    ------------ EXAMPLE USAGE --------------------------
   %    % This example gets a few minutes of data (starting a day ago) from
   %    % a ficticious winston server.  Data returned is for the EHZ channel
   %    % at each of the three selected stations.
   %
   %    myStations = {'OKCF','PV6','SSLS'};  myChannels = 'EHZ';
   %    scnlList = channeltag(myStations,myChannels,'AV','--');
   %
   %    mySource = datasource('winston','servername.here.edu',1255);
   %
   %    w = waveform(mySource, scnlList, now - 1, now - .98);
   %
   %
   % ------------ DEPRECATED USAGE ---------------
   %   w = WAVEFORM(station, channel, samplerate, starttime, data)
   %          manually puts together a waveform object from the minimum
   %          required fields.
   %          Deprecated because: station and channel do not adequately
   %          describe the channel.
   %
   % see also channeltag, DATASOURCE
   
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
   
   % do we combine waveforms, or not?  If NOT, then the last argument will be
   % 'nocombine'. otherwise the constructor will attempt to combine waveforms
   argCount = nargin;
   if argCount>0 && ischar(varargin{end}) && strcmpi(varargin{end},'nocombine')
      varargin(end) = [];
      argCount = argCount - 1;
      COMBINE_WAVES = false;
   else
      COMBINE_WAVES = true;
   end
   
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
         if isa(varargin{1},'channeltag')
            % channeltag, freq, startt, data
            w = waveformFromParts(varargin{:}, 'Unk');
         elseif isa(varargin{1}, 'datasource')
            % eg.  w = waveform(datasource, channeltags, startTimes, endTimes)
            
            [ds, chans, startt, endt] = deal(varargin{:});
            
            startt = ensure_dateformat(startt);
            endt = ensure_dateformat(endt);
            
            % -------------------------------------------------------------------
            % if there is no specifically assigned load function, then
            % determine the load function based upon the datasource's type
            
            if isVoidInterpreter(ds)
               ds_type  = get(ds,'type');
               switch lower(ds_type)
                  
                  % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                  % file, sac, and seisan all do not require fancy handling.  The
                  % load routine and interpreter will be set, and the waveform will
                  % be loaded in the following section, along with any user-defined
                  % load functions.
                  case {'file','sac','seisan','obspy'}
                     myLoadRoutine = eval(['@load_',ds_type]);
                     ds = setinterpreter(ds,myLoadRoutine); %update interpeter funct
                     
                     % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                     % both winston and antelope are database types, which require
                     % fancier handling.  Their waveforms will be loaded right here.
                  case {'winston'}
                     myLoadRoutine = eval(['@load_',ds_type]);
                     w = myLoadRoutine( makeDataRequest(ds,chans,startt,endt) );
                  case {'antelope'}
                     myLoadRoutine = eval(['@load_',ds_type]);
                     %makeDataRequest(ds,chans,startt,endt)
                     w = myLoadRoutine( makeDataRequest(ds,chans,startt,endt) ,COMBINE_WAVES);
                     % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                     % Future pre-defined load types would have case statments here
                     % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                     
                     % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                     % There was no interpreter set, but there was no default type
                     % set, either.
                  case {'irisdmcws'}
                     myLoadRoutine = eval(['@load_',ds_type]);
                     w = myLoadRoutine( makeDataRequest(ds, chans, startt, endt) , COMBINE_WAVES);
                     
                  otherwise
                     error('Waveform:waveform:noDatasourceInterpreter',...
                        'user defined datasources should be associated with an interpreter');
               end
            end
            
            
            % -------------------------------------------------------------------
            % if the datasource is file based, or if it requires a user-defined
            % intepreter function, then do what follows.  Otherwise, we're done
            
            if ~isVoidInterpreter(ds)
               myLoadFunc = get(ds,'interpreter');
               
               %user_defined datasource
               for j = 1:numel(startt)
                  myStartTime = startt(j);
                  myEndTime = endt(j);
                  
                  % grab all files for date range, discarding duplicates
                  fn = getfilename(ds, chans,subdivide_files_by_date(ds,myStartTime, myEndTime));
                  fn = unique(fn);
                  
                  %load all waveforms for these files
                  clear somew
                  for i=1:numel(fn)
                     possiblefiles = dir(fn{i});
                     if isempty(possiblefiles)
                        disp(['no file:',fn{i}]);
                        continue,
                     end
                     
                     [PATHSTR,~,~] = fileparts(fn{i});
                     for nfiles = 1:numel(possiblefiles)
                        w(nfiles) = myLoadFunc(fullfile(PATHSTR,possiblefiles(nfiles).name));
                     end
                     if isempty(w)
                        warning('Waveform:waveform:noData','no data retrieved');
                        return
                     end
                     %combine and get rid of exterreneous waveforms
                     w = w(ismember(w,chans)); %keep only appropriate station/chan
                     if isempty(w)
                        warning('Waveform:waveform:noData','no relevent data retrieved');
                        return
                     end
                     % subset and consolidate
                     [wstarts, wends] = gettimerange(w);
                     w = w(wstarts < myEndTime & wends > myStartTime);
                     if numel(w) > 0 %9/23/2009 condition
                        w = extract(w,'time',myStartTime,myEndTime);
                        somew(i) = {w(:)'};
                     else
                        disp('empty waveform')
                        continue;
                     end
                  end
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
            
         else
            %old waveform way of doing things
            % input: datasource, station, channel, startt, endt
            warning(updateWarningID,updateWarningMessage);
            w = waveform(datasource('uaf_continuous'),...
               channeltag('', varargin{1}, '', varargin{2}),...
               datenum(varargin{3}),...
               datenum(varargin{4}));
         end
         
      case 5
         arg1 = varargin{1};
         load_from_datasource = isa(arg1,'datasource');
         create_from_tag = isa(arg1,'channeltag');
         create_from_text = isa(arg1,'char');
         create_from_scnl = isa(arg1, 'scnlobject');
         
         if create_from_text
            chans = channeltag(arg1);
         elseif create_from_tag
            chans = arg1;
         elseif create_from_scnl
            chans = get(arg1,'channeltag');
         end
         
         if load_from_datasource
            % invoke the "standard" way of importing a waveform
            [ds, chans, startt, endt] = deal(varargin{:});
         else
            w = waveformFromParts(varargin{:});
            return;
         end
         % currently three options if there is a fifth argument
         % 1. logical: 'true' use Yun Wang's modification to not exit for databases with errors
         %             'false' can be set to check the slow-down caused by this procedure,
         %             but it will only work if there are no database errors
         % 2. string:  specify alternate directory
         % 3. real:    vector of data
         
         
         if islogical(varargin{5})
            if load_from_datasource
               % invoke the "standard" way of importing a waveform
               % eg. w = waveform(datasource,channeltags,startTimes,endTimes)
               
               % reassign the function arguments into meaningful variables
               [ds, chans, startt, endt, bwkaround] = deal(varargin{:});
               
               % ensure proper date formatting
               startt = ensure_dateformat(startt);
               endt = ensure_dateformat(endt);
               % -------------------------------------------------------------------
               % if there is no specifically assigned load function, then
               % determine the load function based upon the datasource's type
               
               if isVoidInterpreter(ds)
                  ds_type  = get(ds,'type');
                  switch lower(ds_type)
                     
                     % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                     % file, sac, and seisan all do not require fancy handling.  The
                     % load routine and interpreter will be set, and the waveform will
                     % be loaded in the following section, along with any user-defined
                     % load functions.
                     case {'file','sac','seisan'}
                        myLoadRoutine = eval(['@load_',ds_type]);
                        ds = setinterpreter(ds,myLoadRoutine); %update interpeter funct
                        
                        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        % both winston and antelope are database types, which require
                        % fancier handling.  Their waveforms will be loaded right here.
                     case {'winston'}
                        myLoadRoutine = eval(['@load_',ds_type]);
                        w = myLoadRoutine( makeDataRequest(ds,chans,startt,endt) );
                     case {'antelope'}
                        myLoadRoutine = eval(['@load_',ds_type]);
                        if bwkaround
                           myLoadRoutine = eval(['@load_','antelope_workaround']);
                        end
                        %makeDataRequest(ds,chans,startt,endt)
                        w = myLoadRoutine( makeDataRequest(ds,chans,startt,endt) ,COMBINE_WAVES);
                        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        % Future pre-defined load types would have case statments here
                        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        
                        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        % There was no interpreter set, but there was no default type
                        % set, either.
                     case {'irisdmcws'}
                        myLoadRoutine = eval(['@load_',ds_type]);
                        w = myLoadRoutine( makeDataRequest(ds, chans, startt, endt) , COMBINE_WAVES);
                        
                     otherwise
                        error('Waveform:waveform:noDatasourceInterpreter',...
                           'user defined datasources should be associated with an interpreter');
                  end
               end
               
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
                        w = w(ismember(w,chans)); %keep only appropriate station/chan
                        w = filter_by_time(w, myStartTime, myEndTime);
                        if numel(w) > 0
                           somew(i) = {w};
                        end
                     end
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
               
            else
               %old waveform way of doing things
               error(updateWarningID,updateWarningMessage);
            end %isa(varargin{1},'datasource')
            
         elseif ischar(varargin{5})       % 5th argument is a directory
            
            error(updateWarningID,updateWarningMessage);
         else                             % 5th argument is real data
            % INPUT: waveform (station, channel, frequency, starttime, data)
            tag = channeltag([], varargin{1}, [], varargin{2});
            w = waveformFromParts(tag, varargin{3}, varargin{4}, varargin{5}, 'Unk');
         end
         
      case 8
         w = winstonAccess(varargin{:});
      otherwise
         
         disp('Invalid arguments in waveform constructor:');
         disp(varargin);
         disp('valid ways of calling waveform include: ');
         disp('   w = WAVEFORM() creates an "empty" waveform');
         disp('   w = WAVEFORM(datasource, channeltag, starttimes, endtimes)');
         disp('   w = WAVEFORM(channeltag, samplefreq, starttime, data, units)');
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
      w.data = double(data);
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
   startindex = 1;
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
