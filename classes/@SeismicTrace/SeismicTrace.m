classdef SeismicTrace < TraceData
   %SeismicTrace   Control seismic data including channel and time info
   %  SeismicTrace inherits the ability to manipulate timeseries data from
   %  TraceData, and adds the capability to handle chanel descriptor tags,
   %  handle userdata fields, track history, timestamping, and basic 
   %  calibration.
   %
   %  SeismicTrace is the replacement class for waveform
   %
   %  See also retrieve, TraceData, waveform, ChannelTag
   
   % Author: Celso Reyes, unless otherwise specified in the class functions
   % Contributions by: Glenn Thompson, Michael West, Carl Tape
   % Based on waveform, by Celso Reyes
   
   properties(Dependent)
      % Network.Station.Location.Channel code, as char.
      % By setting the name, the related network, station, location,
      % channel, and channelinfo fields are also set
      % see also network, station, location, channel, channelinfo
      name % N.S.L.C code
      network % network code
      station % station code
      location % location code
      channel % channel code
      start
   end
   
   properties
      % history, stored as a structure of (what, when),
      % where "what" can be anything, and "when" is a matlab datenum
      % see also SeismicTrace.addhistory, SeismicTrace.clearhistory
      history = struct('what','created SeismicTrace','when',now); 
      % structure containing user-defined fields
      % Field names are case sensitive.
      % Field values can be validated if a UserDataRule is specified.
      % 
      % see also SeismicTrace.userdata, SeismicTrace.setUserDataRule,
      % SeismicTrace.renameUserField
      userdata = struct();
      % contains calibration values for this trace.
      % see also SeismicTrace.setcalib, SeismicTrace.removecalib, SeismicTrace.applycalib
      calib = struct('value',1,'applied',false);
      
      %struct that mirrors userdata, but contains two fields:
      %   allowed_type: a class name (or empty). If this
      %   exist, then when data is assigned to userdata, it
      %   will be type-checked.
      %   min_count, max_count: if empty,any sized array can be
      %   assigned to this field.  If a single number, then
      %   eac assignment must have exactly this number of values.
      %   if [min max], then any number of values between min
      %   and max inclusive may be assigned to this.
      % see also SeismicTrace.userdata, SeismicTrace.setUserDataRule,
      % SeismicTrace.renameUserField
      UserDataRules 
   end
   
   properties(Hidden)
      mat_starttime % start time in matlab-time
      channelinfo = ChannelTag; % channelTag
   end
   
   properties(Hidden, Dependent)
   end
   
   methods
      function obj = SeismicTrace(varargin)
         %SeismicTrace   Constructor for SeismicTrace objects
         %   St=SeismicTrace will return an empty SeismicTrace
         %   St=SeismicTrace(waveform) creates a SeismicTrace from a
         %   waveform objct. This might get removed and put into waveform
         %
         %   See also TraceData, ChannelTag, Waveform
         
         obj@TraceData(varargin{:});
         switch nargin
            case 1
               if isa(varargin{1}, 'waveform')
                  obj.channelinfo = get(varargin{1},'channeltag');
                  obj.mat_starttime = get(varargin{1}, 'start');
                  
                  H = get(varargin{1}, 'history');
                  for n=1:size(H,1);
                     if isempty(H{n,1}) || isempty(H{n,2})
                        continue
                     end
                     obj.history(end+1).what = H{n,1};
                     obj.history(end).when = H{n,2};
                  end
                  miscFields = get(varargin{1},'misc_fields');
                  for n = 1: numel(miscFields)
                     if ~isempty(miscFields{n})
                        obj.userdata.(miscFields{n})= get(varargin{1},miscFields{n});
                     end
                  end
               else
                  error('SeismicTrace:unknownConversion',...
                     'Do not know how to make a SeismicTrace from a %s',...
                     class(varargin{1}));
               end
                  
         end %switch
      end
      
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
      
      %%
      function st = get.start(obj)
         st = datestr(obj.mat_starttime,'yyyy-mm-dd HH:MM:SS.FFF');
      end
      
      function obj = set.start(obj, v)
         if isnumeric(v) && numel(v) == 1
            obj.mat_starttime = v;
         elseif ischar(v)
            obj.mat_starttime = datenum(v);
         else
            error('do not understand start assignment. must be a matlab datenum or a string')
         end
         % could add ability to translate from java or datetime
      end
      function val = sampletimes(obj)
         %sampletimes   Retrieve matlab date for each sample
         %
         %   Replaces waveform's get(w, 'timevector')
         
         val = sampletimes@TraceData(obj) + obj.mat_starttime;
      end
      
      function val = firstsampletime(obj, stringformat)
         %firstsampletime   Time of first sample as matlab date or string.
         %  val = trace.lastsampletime will return as a datenum
         %  val = trace.lastsampletime(FORMAT) will return a string
         %  formatted according to FORMAT.
         %  For multiple traces, a character array will be returned.
         %
         %  See also datestr
         val = [obj.mat_starttime];
         if exist('stringformat','var')
            val = datestr(val,stringformat);
         else
            val = reshape(val,size(obj));
         end
      end
      function val = lastsampletime(obj, stringformat)
         %lastsampletime   Time of last sample as matlab date or string.
         %  val = trace.lastsampletime will return as a datenum
         %  val = trace.lastsampletime(FORMAT) will return a string
         %  formatted according to FORMAT.
         %
         %  For multiple traces, a character array will be returned.
         %  See also datestr
         secDurs = [obj.duration];
         assert(all(~isnan([obj.samplerate])),...
            'SeismicTrace:lastsampletime:Uncalculatable',...
            'Missing samplerate for one or more waveforms. lastsampletime is incalculable');
         secDurs(secDurs > 0) = secDurs - 1./[obj.samplerate];
         val = [obj.firstsampletime] + secDurs/86400;
         if exist('stringformat','var')
            val = datestr(val,stringformat);
         else
            val = reshape(val,size(obj));
         end
      end
      
      function tf = startsbefore(A, B)
         %startsbefore   Compare starttimes of SeismicTrace
         %   tf = A.startsbefore(B)  will return TRUE if Trace A starts
         %   before trace B starts. 
         %
         %   If B is something other than a SeismicTrace, then it will try
         %   to convert to a MATLAB datenum before converting.  
         %   
         %   See also: startsafter, endsbefore, endsafter, datenum,
         %   datetime
         if isa(B,'SeismicTrace')
            tf = A.firstsampletime < B.firstsampletime;
         else % handle datenums, datestrings, or datetimes
            tf = A.firstsampletime < datenum(B);
         end
      end
      
      function tf = startsafter(A, B)
         %startsafter   Compare starttimes of SeismicTrace
         %   tf = A.startsafter (B) will return TRUE if Trace A starts after
         %   Trace B.
         %
         %   If B is something other than a SeismicTrace, then it will try
         %   to convert to a MATLAB datenum before converting.  
         %   
         %   See also: startsafter, endsbefore, endsafter, datenum,
         %   datetime
         if isa(B,'SeismicTrace')
            tf = A.firstsampletime > B.firstsampletime;
         else % handle datenums, datestrings, or datetimes
            tf = A.firstsampletime > datenum(B);
         end
      end
      function tf = endsbefore(A, B)
         %endsbefore   Compare last samples of SeismicTrace
         %   tf = A.endsbefore (B)  will return TRUE if Trace A ends before
         %   trace B
         %
         %   If B is something other than a SeismicTrace, then it will try
         %   to convert to a MATLAB datenum before converting.  
         %   
         %   See also: startsafter, endsbefore, endsafter, datenum,
         %   datetime
         if isa(B,'SeismicTrace')
            tf = A.lastsampletime < B.lastsampletime;
         else % handle datenums, datestrings, or datetimes
            tf = A.lastsampletime < datenum(B);
         end
      end
      function tf = endsafter(A, B)
         %endsafter   Compare last samples of SeismicTrace
         %   tf = A.endsafter (B) will return TRUE if Trace A ends after
         %   Trace B.
         %
         %   If B is something other than a SeismicTrace, then it will try
         %   to convert to a MATLAB datenum before converting.  
         %   
         %   See also: startsafter, endsbefore, endsafter, datenum,
         %   datetime
         if isa(B,'SeismicTrace')
            tf = A.lastsampletime > B.lastsampletime;
         else % handle datenums, datestrings, or datetimes
            tf = A.lastsampletime > datenum(B); 
         end
      end
      
      function s = get.name(T)
         if numel(T) ==1
            s = T.channelinfo.string;
         else
            s=arrayfun(@(x) x.channelinfo.string, T, 'UniformOutput',false);
         end
      end
      function T = set.name(T, val)
         assert(numel(T) == 1, 'only can set name for individual traces');
         T.channelinfo = ChannelTag(val);
      end
      
      function T = align(T,alignTime, newSamprate, method)
         %align   Resample a seismic trace over a specified interval
         %   T = T.align(alignTime, newSamprate)
         %   T = T.align(alignTime, newSamprate, method)
         %
         %   Input Arguments
         %       T: SeismicTrace      N-dimensional
         %       ALIGNTIME: either a single matlab time or an array of times
         %       the same shape as the input TRACE matrix.
         %       NEWSAMPRATE: sample rate of the newly aligned traces
         %       in samples/second
         %       METHOD: Any of the methods listed in function INTERP1
         %          If omitted, then the default is '<a href="matlab: help pchip">pchip</a>'
         %
         %   Output
         %       The output waveform has the new samplerate newSamprate and a
         %       a starttime calculated by the specified method, using 
         %       the <a href="matlab: help interp1">interp1</a> function.
         %
         %   METHODOLOGY
         %     The alignTime is projected forward or backward in time at the
         %     specified sample interval until it approaches the original waveform's
         %     start time.  The rest of the waveform is then interpolated at the
         %     sample rate.
         %
         %     Methodology Example.
         %         A waveform starts on 1/1/2008 12:00, with sample rate of 10
         %         samples/sec, and has data covering 10 minutes  (6000 samples).
         %         The resampled data is requested for time 1/1/2008 12:05:00.03,
         %         also at 10 samples/sec.
         %         The resulting data will start at 1/1/2008 12:00:00.3, and have
         %         5999 samples, with the last sample occurring at 12:09:59.830.
         %
         %   Examples of usefulness?  Particle motions, coordinate transformations.
         %   If used for particle motions, consider <a href="matlab:help plotmatrix">plotmatrix</a> command.
         %
         %   example:
         %       chanNames = {'AV.KDAK..BHZ','AV.KDAK.BHN','AV.KDAK.BHE'};
         %       tags = ChannelTag(chanNames); %grab all 3 channels
         %       % for each component, grab winston data on Kurile Earthquake
         %       T = Trace.retrieve(mydatasource,tags,'1/13/2007 04:20:00','1/13/2007 04:30:00');
         %       T = T.align('1/37/2007 4:22:00', w(1).samplerate);
         %
         %
         % See also interp1, plotmatrix
         
         
         oneSecond = 1/86400;
         
         if ~exist('method','var')
            method = 'pchip';
         end
         
         if ischar(alignTime),
            alignTime =  datenum(alignTime);
         end
         
         oneAlignTime = numel(alignTime) == 1;
         hasCompatibleSize = oneAlignTime || ... single align time OR
            all(size(alignTime) == size(T)) || ... same shape OR
            (numel(alignTime) == length(T) && ... both vectors have
            numel(T) == length(alignTime));     % the same length
         
         assert(hasCompatibleSize, 'SeismicTrace:align:invalidAlignSize',...
            'alignTime must be either a single time or a matrix the same shape as the traces');
         
         if oneAlignTime % same align time for all traces
            alignTime = repmat(alignTime,size(T));
         end
         
         
         newSamplesPerSec = 1 / newSamprate ;  %# samplesPerSecond
         timeStep = newSamplesPerSec * oneSecond;
         existingStarts = T.firstsampletime;
         existingEnds = T.lastsampltime;
         
         % calculate the offset of the closest "aligned" time, by projecting the
         % desired sample rate and time forward or backward onto these waveforms'
         % start time.
         deltaTime = existingStarts - alignTime;  % time in between
         % if deltatime (-):alignTime AFTER existingStarts,
         % if deltatime (+):alignTime BEFORE existingStarts
         closestStartTime = existingStarts - rem(deltaTime,timeStep);
         
         for n=1:numel(T)
            origTimes = T(n).sampletimes;
            % newTimes MUST be in one column, else DATA field gets corrupted
            newTimes = ( closestStartTime(n):timeStep:existingEnds(n) )';
            
            %get rid of samples that lay entirely outside the existing waveform's
            %range (ie, only interpolate values BETWEEN points)
            newTimes(newTimes < origTimes(1) | newTimes > origTimes(end)) = [];
            
            T(n).data = interp1(...
               origTimes,...     original times (x)
               T(n).data,...         original data (y)
               newTimes,...    new times (x1)
               method);           %  method
            T(n).start = newTimes(1); % must be a datenum
            T(n).samplerate = newSamprate;
         end
         
         %% update histories
         % if all waves were aligned to the same time, then handle all history here
         if oneAlignTime
            noteRealignment(T, alignTime(1), newSamprate);
         else
            for n=1:numel(T)
               T(n) = noteRealignment(T(n), alignTime(n), newSamprate);
            end
         end
         
         function T = noteRealignment(T, startt, samprate)
            timeStr = datestr(startt,'yyyy-mm-dd HH:MM:SS.FFF');
            myHistory = sprintf('aligned data to %s at %f samples/sec', timeStr, samprate);
            T = T.addhistory(myHistory);
         end
      end
      
      %% Handling User-defined fields
      %TODO: Guarentee or document how the userfield things work for
      %multiple trace objects. First thought: They should be performed
      %individually, on a single object
      %
      % waveform/delfield has been replaced by using matlab's rmfield:
      % T.userdata = rmfield(T.userdata, 'fieldToDelete');
      
      % isfield is not implemented because matlab's can be used:
      % isfield(T.userdata,'something');
      
      function T = set.userdata(T, val)
         %sets userdata fields for a trace object
         % T.userdata.myfield = value;
         %
         % to impose constraings on the values that this field can
         % retrieve, use: SeismicTrace.SetUserDataRule(myfield,...)
         %
         % to delete the field:
         % T.userdata = rmfield(T.userdata, 'fieldToRemove');
         % see also SeismicTrace.SetUserDataRule, rmfield
         oldfields = fieldnames(T.userdata);
         fn = fieldnames(val);
         fieldToAdd = fn(~ismember(fn, oldfields));
         if ~isempty(fieldToAdd) && any(strcmpi(fieldToAdd, oldfields))
            % we have a case change!! uh-oh.
            similarlyNamed = oldfields{strcmpi(oldfields, fieldToAdd)};
            error(['attempted to add field [''%s''], '...
               'but a similar field [''%s''] exists.\n'...
               'Check your case and try again'],...
               fieldToAdd{1}, similarlyNamed);
         end
         %fn_existing = fieldnames(T.userdata);
         %newfn = ~ismember(fieldnames(val),val
         for f = 1:numel(fn);
            testUserField(T, fn{f}, val.(fn{f}))
         end
         T.userdata = val;
      end
      
      function T = renameUserField(T, oldField, newField, failSilently)
         %renameUserField   Rename a userdata field
         %  T = T.renameuserField(oldName, newName);
         %  rename a field if it exists to a new name.
         % 
         %  Also renames the associated Rules field
         %
         %  Possible sticking-points to deal with:
         %  1. both oldField and newField exist in T.userdata -> error
         %  2. newField already exists in T.userdata -> ignore
         %  3. neither newField or oldfield exists in T.Userdata -> warning
         % 
         %  if failSilently is true, then failures will not result in an
         %  error.
         %
         %  See also: userdata, userDataRule
         
         
         oldFieldExists = isfield(T.userdata, oldField);
         newFieldExists = isfield(T.userdata, newField);
         sameNames = strcmp(oldField, newField);
         if ~exist('failSilently', 'var'); failSilently = false; end;
         if sameNames
            if failSilently
               return
            else
               warning('oldField is the same as newField [%s]. Ignoring', oldField);
               return
            end
         end
         if oldFieldExists
            if newFieldExists %BOTH fields exist
               if (~isempty(newField))  %but the new one isn't empty
                  error('Both fields already exist, and userdata.%s already contains data',newField);
               else % but the new one is empty, so proceed normally
                  if ~failSilently
                     warning('Both fields exist, but since userdata.%s is empty, its value is being replaced', newField);
                  end
                  T.userdata = mvField(T.userdata, oldField, newField);
                  if isfield(T.UserDataRules,oldfield);
                     T.UserDataRules = mvField(T.UserDataRules,oldField, newField);
                  end
                     
               end
            else % only the old field exists, so proceed normally
               
                  T.userdata = mvField(T.userdata, oldField, newField);
                  if isfield(T.UserDataRules,oldfield);
                     T.UserDataRules = mvField(T.UserDataRules,oldField, newField);
                  end
            end
         else
            if newFieldExists  %only the new field exists
               % already renamed. ignore
            else % neither field exists
               if ~failSilently
                 warning('field [%s] does not exist in userdata', oldField);
               end
            end
         end
         
         function subfield = mvField(subfield, oldField, newField)
            tmp = subfield.(oldField);
            subfield = rmfield(subfield,oldField);
            [subfield.(newField)] = tmp;
         end
      end
      
      function testUserField(obj, fn, value)
         %testUserField   apply the testing rules to a userdata field
         %  will error with detailed information about how the field fails
         %  validation.
         %
         %  see also setUserDataRule
         
         if ~isfield(obj.UserDataRules,fn)
            return;
         end
         if ~isfield(obj.userdata,fn)
            if exist('value','var')
               % continue on
            else
               return
            end
         end
         rules = obj.UserDataRules.(fn);
         if ~rules.inUse
            return
         end
         if ~exist('value','var')
            value = obj.userdata.(fn);
         end
         % test the type
         if ~isempty(rules.allowed_type) && ...
               ~isa(value, rules.allowed_type)
            error('User-defined field [%s] requires input of class [%s], but value was a [%s]',...
               fn, rules.allowed_type, class(value));
         end
         % test the number of items
         if ~isempty(rules.min_count) && numel(value) < rules.min_count
            error('User-defined field [%s]: Size of value [%d] is too small. Min allowed size is %d',...
               fn, numel(value), rules.min_count);
         end
         if ~isempty(rules.max_count) && numel(value) > rules.max_count
            error('User-defined field [%s]: Size of value [%d] is too big. Max allowed size is %d',...
               fn, numel(value), rules.max_count);
         end
         % test the value (only works for numeric types)
         if ~isempty(rules.min_value) && value < rules.min_value
            error('User-defined field [%s]: Assigned value [%f] is too small. Min allowed is %f',...
               fn, value, rules.min_value);
         end
         if ~isempty(rules.max_value) && value >rules.max_value
            error('User-defined field [%s]: Assigned value [%f] is too big. Max allowed is %f',...
               fn, value, rules.max_value);
         end
      end
      
      function T = setUserDataRule(T, fieldname, allowedType, allowedCount, allowedRange)
         %setUserDataRule   create rules to govern data entry into userdata fields.
         % T = T.setUserData(fieldname, classname) will have the class
         % checked each time a value is assigned to the userdata
         % field T.userdata.fieldname.
         %
         % T = T.setUserDataRule(fieldname, classname, count) controls the
         % array size for any assignments to T.userdata.fieldname.  count
         % may be a single number N or a range [nMin nMax]
         % for any value assigned to T.userdata.fieldname,
         %    numel(value) == N or Nmin <= numel(value) <= Nmax
         %
         % T = T.setUserDataRule(fieldname, classname, count, range)
         % for numeric classes, range will specify the min/max values.
         %
         % T = T.setUserDataRule(fieldname) will clear the constraints.
         % examples:
         % T = T.setUserDataRule('height','double',1, [0 inf]); will ensure
         % that height will always be a scalar positive double
         % ...setUserDataRule('code','char',[1 4]) will ensure that any
         % assignments to T.userdata.code will be a string between 1 and 4
         % characters in length.
         %
         % See also testUserField, renameUserField, 
         assert(ischar(fieldname))
         if ~exist('allowedType', 'var')
            T.UserDataRules.(fieldname).inUse = false;
            return
         else
            T.UserDataRules.(fieldname).inUse = true;
         end
         %add the rules to UserDataRules
         if ischar(allowedType) || isempty(allowedType)
            T.UserDataRules.(fieldname).allowed_type = allowedType;
         else
            error('AllowedType must be a class name or empty');
         end
         
         if ~exist('allowedCount', 'var')
            allowedCount = [];
         end
         if isnumeric(allowedCount)
            switch numel(allowedCount)
               case 0
                  T.UserDataRules.(fieldname).min_count = -inf;
                  T.UserDataRules.(fieldname).max_count = inf;
               case 1
                  T.UserDataRules.(fieldname).min_count = allowedCount;
                  T.UserDataRules.(fieldname).max_count = allowedCount;
               case 2
                  T.UserDataRules.(fieldname).min_count = allowedCount(1);
                  T.UserDataRules.(fieldname).max_count = allowedCount(2);
               otherwise
                  error('allowedCount must be either empty, or numeric with 1 or 2 values');
            end
         else
            error('allowedCount must be either empty, or numeric with 1 or 2 values');
         end
         
         if ~exist('allowedRange', 'var') || strcmp(allowedType,'char')
            allowedRange = [];
         end
         if isnumeric(allowedRange)
            switch numel(allowedRange)
               case 0
                  T.UserDataRules.(fieldname).min_value = [];
                  T.UserDataRules.(fieldname).max_value = [];
               case 2
                  T.UserDataRules.(fieldname).min_value = allowedRange(1);
                  T.UserDataRules.(fieldname).max_value = allowedRange(2);
               otherwise
                  error('allowedRange must be either empty, or [min max]');
            end
         else
            error('allowedRange must be either empty, or [min max]');
         end
      end
      
      %%
      function [T, I] = sortby(T, criteria)
         %sortby   sort SeismicTraces based on a property
         %  Tsorted = sortby(Tin) sorts by the name (N.S.L.C) in
         %  purely alphabetical order. Depending on the length of each
         %  field, the final results may not be in an expected order.
         %
         %  Tsorted = sortby(Tin, cirt), where CRIT is a valid property
         %
         % [Wsorted, I] = sortby(Win...) will also return the index list so that
         %     Win(I) = Wsorted
         %
         %   Examples:
         %   tSorted = T.sortby('samplerate');  % sort by sample rate
         %   tSorted = T.sortby('firstsample'); % sort by start time
         %   tSorted = T.sortby('station');     % sort by station name
         %   tSorted = T.sortby('duration');    % sort by the duration
         %   tSorted = T.sortby('var');         % sort bythe variance
         %
         %   Generally, if you can request a scalar value from a Seismic
         %   Trace using function A, then 'A' is a valid criteria.
         %
         %   Advanced usage:
         %   sortby also accepts functions, so that the following example is
         %   valid:
         %     myfunc = @(x) median(x) - min(x);
         %     Tsorted = T.sortby(myfunc)
         %
         %
         % see also: sort
                  
         if nargin < 2
            criteria = 'name';
         end
         if ischar(criteria)
            % could be a property or a method
            if ismember(criteria,properties(T))
               if ischar(T(1).(criteria))
               [~,I] = sort({T.(criteria)});
               else
               [~,I] = sort([T.(criteria)]);
               end
            elseif ismethod(T,criteria)
               [~,I] = sort(T.(criteria));
            end
         elseif isa(criteria, 'function_handle')
            [~, I] = sort(criteria(T));
         else
            error('unable to sort');
            % TODO: add ability to sort userdata fields
         end
         % sort by a field
         % [~, I] = sort(get(T,criteria));
         T = T(I);
      end

      function combined_traces = combine (traces)
         %combine   Merge waveforms based on start/end times and ChannelTag
         %  combined_waveforms = combine(traces) combines based on
         %  ChannelTag and start/endtimes. 
         %
         % DOES NO OTHER CHECKS
                  
         if numel(traces) == 0  %nothing to do
            combined_traces = traces;
            return
         end
         
         chaninfo = [traces.channelinfo];
         [uniquechans, ~, chanbin] = unique(chaninfo);
         
         %preallocate
         combined_traces = repmat(SeismicTrace,size(uniquechans));
         
         for i=1:numel(uniquechans)
            T = traces(chanbin == i);
            T = timesort(T);
            for j=(numel(T)-1):-1:1
               T(j) = pieceTogether(T(j), T(j+1));
               T(j+1) = [];
            end
            combined_traces(i) = T;
         end
         
         function Tout = pieceTogether(T1, T2)
            %pieceTogether
            if isempty(T1.data)
               Tout = T2;
               return;
            end;
            dtSecs = (T2.firstsampletime - T1.lastsampletime) * 86400;
            sampRate = T1.samplerate;
            if sampRate > 1
               sampRate = round(sampRate);
            elseif sampRate > 0
               sampRate = 1 / (round(1 / sampRate));
            end
            sampleInterval = 1 ./ sampRate;
            overlaps = (dtSecs - sampleInterval .* 1.25) < 0;
            if overlaps
               Tout = spliceTrace(T1, T2);
            else
               paddingAmount = round((dtSecs * sampRate)-1);
               Tout = spliceAndPad(T1,T2, paddingAmount);
            end
         end
         
         function T1 = spliceAndPad(T1, T2, nToPad)
            %spliceAndPad   Combine two traces that do not overlap
            if nToPad > 0 && ~isinf(nToPad)
               T1.data = [T1.data; nan(nToPad,1); T2.data];
            else
               T1.data = [T1.data; T2.data];
            end
         end
         
         function T1 = spliceTrace(T1, T2)
            %spliceTrace   combines two traces that  overlap
            timesToGrab = sum(T1.sampletimes < T2.firstsampletime);
            samplesRemoved = numel(T1.data) - timesToGrab;
            T1.data = [double(extract(T1,'index',1,timesToGrab)); T2.data];
            T1= T1.addhistory('SPLICEPOINT: %s, removed %d points (overlap)',...
               T2.start, samplesRemoved);
         end
                  
         function T = timesort(T)
            [~, I] = sort([T.mat_starttime]);
            T = T(I);
         end
      end
      
      
         %TODO: make this SeismicTrace-y.  This is currently written for waveforms
         %TODO: Decide on proper wording! Should this be multiple functions?
      function outW = extract(T, method, startV, endV)
         %extract   creates a waveform with a subset of another's data.
         %   waveform = extract(waveform, 'TIME', startTime, endTime)
         %       returns a waveform with the subset of data from startTime to
         %       endTime.  Both times are matlab formatted (string or datenum)
         %
         %   waveform = extract(waveform, 'INDEX', startIndex, endIndex)
         %       returns a waveform with the subset of data from StartIndex to
         %       EndIndex.  this is roughly equivelent to grabbing the waveform's
         %       data into an array, as in D = get(W,'data'), then returning a
         %       waveform with the subset of data,
         %       ie. waveform = set(waveform,'data', D(startIndex:endIndex));
         %
         %   waveform = extract(waveform, 'INDEX&DURATION', startIndex, duration)
         %       a hybrid method that starts from data index startIndex, and then
         %       returns a specified length of data as indicated by duration.
         %       Duration is a matlab formatted time (string or datenum).
         %
         %   waveform = extract(waveform, 'TIME&SAMPLES', startTime, Samples)
         %       a hybrid method that starts from data index startIndex, and then
         %       returns a specified length of data as indicated by duration.
         %       Duration is a matlab formatted time (string or datenum).
         %
         %   Input Arguments:
         %       WAVEFORM: waveform object        N-DIMENSIONAL
         %       METHOD: 'TIME', or 'INDEX', or 'INDEX&DURATION'
         %           TIME: starttime and endtime are absolute times
         %                   (include the date)
         %           INDEX: startt and endt are the offset (index) within the data
         %           INDEX&DURATION: first value is an offset (index), the next says
         %                           how much data to retrieve...
         %           TIME&SAMPLES: grab first value at time startTime, and grab
         %                         Samplength data points
         %       STARTTIME:  Start time (matlab or text format)
         %       ENDTIME:    End time (matlab or text format)
         %       STARTINDEX: position within data array to begin extraction
         %       ENDINDEX:   final grabbed position within data array
         %       DURATION:   matlab format time indicating duration of data to grab
         %       SAMPLES: the number of data points to grab.
         %
         %   the output waveform will have the new, appropriate start time.
         %   if the times are outside the range of the waveform object, then the
         %   output waveform will contain only the portion of the data that is
         %   appropriate.
         %
         %   *MULTIPLE EXTRACTIONS* can be received if the time values are vectors.
         %   Both starttime/startindex and endtime/endindex/endduration/samples must
         %   have the same number of elements.  In this case the output waveforms
         %   will be reshaped with each waveform represented by row, and each
         %   extracted time represented by column.  that is...
         %
         %  The output of this function, for multiple waveforms and times will be:
         %         t1   t2  t3 ... tn
         %    -----------------------
         %    w1 |
         %    w2 |
         %    w3 |
         %     . |
         %     . |
         %    wn |
         %
         %
         %%   examples:
         %       % say that Win is a waveform that starts 1/5/2007 04:00, and
         %       % contains 1 hour of data at 100 Hz (360000 samples)
         %
         %       % grab samples between 4:15 and 4:20
         %       Wout = extract(Win, 'TIME', '1/5/2007 4:15:00','1/5/2007 4:20:00');
         %
         %       % grab 3 minutes, starting at the 10000th sample
         %       Wout = extract(Win, 'INDEX&DURATION', 10000 , '0/0/0 00:03:00');
         %
         %
         %%     example of multiple extract:
         %  % declare the times we're interested in
         %         firstsnippet = datenum('6/20/2003 00:00:00');
         %         lastsnippet = datenum('6/20/2003 24:00:00');
         %
         %         % divide the day into 1-hour segments.
         %         % 25 pieces. equivelent to 0:1:24, including both midnights
         %         alltimes = linspace(firstsnippet, lastsnippet, 25);
         %         starttimes = alltimes(1:end-1);
         %         endtimes = alltimes(2:end);
         %
         %         % grab each hour of time, and shove it into wHours
         %         wHours = extract(wDay, 'time',starttimes, endtimes);
         %
         %         scaleFactor = 4 * std(double(wDay));
         %         wHours = wHours ./ scaleFactor;
         % %
         %          for n = 1:length(wHours)
         %            wHours(n) = -wHours(n) + n; %add offset for plotting
         %          end
         %          plot(wHours,'xunit','m','b'); %plot it in blue with at nm scaling
         %          axis ([0 60 1 25])
         %          set(gca,'ytick',[0:2:24],'xgrid', 'on','ydir','reverse');
         %          ylabel('Hour');
         %
         %   See also waveform/extract
                  
         %% Set up condition variables, and ensure validity of input
         MULTIPLE_WAVES = ~isscalar(T);
         
         %if either of our times are strings, it's 'cause they're actually dates
         if ischar(startV)
            startV = datenum(startV);
         end
         if ischar(endV)
            endV = datenum(endV);
         end
         
         if numel(startV) ~= numel(endV)
            error('Waveform:extract:indexMismatch',...
               'Number of start times (or indexes) must equal number of end times')
         end
         
         % are we getting a series of extractions from each waveform?
         MULTIPLE_EXTRACTION = numel(endV) > 1;
         
         if MULTIPLE_WAVES && MULTIPLE_EXTRACTION
            T = T(:);
         end
         
         %%
         if numel(T)==0 || numel(startV) ==0
            warning('Waveform:extract:emptyWaveform','no waveforms to extract');
            return
         end
         outW(numel(T),numel(startV)) = SeismicTrace;
         
         for m = 1: numel(startV) %loop through the number of extractions
            for n=1:numel(T); %loop through the waveforms
               inW = T(n);
               myData = inW.data;
               
               switch lower(method)
                  case 'time'
                     
                     % startV and endV are both matlab formated dates
                     %sampleTimes = get(inW,'timevector');
                     
                     %   ensure the format of our times
                     if startV(m) > endV(m)
                        warning('Waveform:extract:reversedValues',...
                           'Start time prior to end time.  Flipping.');
                        [startV(m), endV(m)] = swap(startV(m), endV(m));
                     end
                     
                     
                     %if requested data is outside the existing waveform, change the
                     %start time, and clear out the data.
                     startsAfterWave = startV(m) > get(inW,'end') ;
                     endsBeforeWave = endV(m) < get(inW,'start');
                     if startsAfterWave || endsBeforeWave
                        myStart = startV(m);
                        myData = [];
                     else
                        %some aspect of this data must be represented by the waveform
                        [myStartI, myStartTime] = time2offset(inW,startV(m));
                        [myEndI] = time2offset(inW,endV(m)) - 1;
                        if isempty(myStartTime)
                           %waveform starts sometime after requested start
                           myStartTime = get(inW,'start');
                           myStartI = 1;
                        end
                        
                        if myEndI > numel(myData)
                           myEndI = numel(myData);
                        end
                        myData = myData(myStartI:myEndI);
                        myStart = myStartTime;
                     end
                     
                  case 'index'
                     %startV and endV are both indexes into the data
                     
                     
                     if startV(m) > numel(myData)
                        warning('Waveform:extract:noDataFound',...
                           'no data after start index');
                        return
                     end;
                     if endV(m) > numel(myData)
                        endV(m) = length(myData);
                        warning('Waveform:extract:truncatingData',...
                           'end index too long, truncating to match data');
                     end
                     
                     if startV(m) > endV(m)
                        warning('Waveform:extract:reversedValues',...
                           'Start time prior to end time.  Flipping.');
                        [startV(m), endV(m)] = swap(startV(m), endV(m));
                     end
                     
                     myData = myData(startV(m):endV(m));
                     sampTimes = inW.sampletimes; % grab individual sample times
                     myStart = sampTimes(startV(m));
                     
                     %index&duration deprecated, since apparently never used
                     
                     
                  case 'time&samples'
                     % startV is a matlab date, while endV is an index into the data
                     sampTimes = get(inW,'timevector'); % grab individual sample times
                     
                     index_to_times = sampTimes >= startV(m); %mask of valid times
                     goodTimes = find(index_to_times,endV(m));%first howevermany of these good times
                     
                     myData = myData(goodTimes); % keep matching samples
                     
                     try
                        myStart = sampTimes(goodTimes(1)); %first sample time is new waveform start
                     catch
                        warning('Waveform:extract:NoDataFound',...
                           'no data');
                        myStart = startV(1);
                     end
                     
                  otherwise
                     error('Waveform:extract:unknownMethod','unknown method: %s', method);
               end
               
               if MULTIPLE_EXTRACTION
                  outW(n,m).start = myStart;
                  outW(n,m).data = myData;
                  %outW(n,m) = set(inW,'start',myStart, 'data', myData);
               else
                  outW(n).start = myStart;
                  outW(n).data = myData;
                  %outW(n) = set(inW,'start',myStart, 'data', myData);
               end
            end % n-loop (looping through waveforms)
         end % m-loop (looping through extractions)
         
         function  [B,A] = swap(A,B)
            %do nothing, just flip inputs & outputs
         end
      end
      
      %TODO: function ismember
      
      %TODO: function calib_apply
      function obj = calibapply(obj)
         %calibapply   scale the data by the nominal calibration value
         %  scaledtraces = calibapply(traces)
         %
         %  because of the nature of floating-point operations, it is
         %  possible that repeated applications of calibapply and
         %  calibunapply would introduce rounding errors
         %
         %  See also calibunapply
         appliedIndex = false(numel(obj));
         for n=1:numel(obj)
            if ~obj(n).calib.applied
               obj(n).data = obj(n).data .* obj(n).calib.value;
               obj(n).calib.applied = true;
               appliedIndex(n) = true;
            else
               warning('SeismicTrace:calibapply:alreadyApplied','Calibratin already applied');
            end
         end
         
         if any(~appliedIndex)
            %could use appliedIndex to give more details
            warning('SeismicTrace:calibapply:alreadyApplied','Calibration already applied');
         end
      end
      function obj = calibunapply(obj)
         %calibunapply  remove calibration from the data (divide by it)
         %  unscaledtraces = calibunapply(traces)
         %
         %  because of the nature of floating-point operations, it is
         %  possible that repeated applications of calibapply and
         %  calibunapply would introduce rounding errors
         %
         %  See also calibapply
         unapplied = false(numel(obj));
         for n=1:numel(obj)
            if obj(n).calib.applied
               obj(n).data = obj(n).data ./ obj(n).calib.value;
               obj(n).calib.applied = false;
               unapplied(n) = true;
            end
         end
         if any(~unapplied)
            %could use appliedIndex to give more details
            warning('SeismicTrace:calibunapply:notApplied','Calibration was not applied');
         end
      end
      %TODO: function calib_remove
      
      %% history-related functions
      function T = addhistory(T, whathappened,varargin)
         %addhistory   function in charge of adding history to a waveform
         %   trace = trace.addhistory(whathappened);
         %   trace = trace.addhistory(formatString, [variables...])
         %
         %   The second way of using addhistory follows the syntax of fprintf
         %
         %   Input Arguments
         %       WAVEFORM: a SeismicTrace object
         %       WHATHAPPENED: absolutely anything.  Really.
         %
         %   AddHistory appends not only what happened, but also keeps track of WHEN
         %   it happened.
         %
         %   example
         %       T = SeismicTrace; %create a blank trace
         %       T = T.addhistory('the following procedures done by DoIt.m');
         %       N = 1; M = 'Today'
         %       T = T.addhistory('this is sample #%d date:%s',N,M);
         %       % what is actually added: "this is sample #1 date:Today"
         %
         % See also SeismicTrace.history, fprintf
         
         if nargin > 2,
            whathappened = sprintf(whathappened, varargin{:});
         end
         modtime = now;
         for N = 1 : numel(T);
            %History is stored in a cell, the format of which is [WHAT, WHEN]
               T(N).history(end+1).what = whathappened;
               T(N).history(end).when = modtime;
         end
      end
      function T = clearhistory(T)
         %clearhistory   reset history of a waveform
         %   trace = trace.clearhistory
         %   clears the history, leaving it blank
         %
         % See also SeismicTrace.addhistory SeismicTrace.history.         
         T(N).history= T(N).history([]);
      end
      function [myhist] = get.history(t)
         %history   retrieve the history of a waveform object
         %   myhist = trace.history
         %       returns a struct describing what's been done to this trace
         %   myhist = trace.history(N)
         %       get Nth element from the history.  End works,too!
         % See also SeismicTrace.addhistory, SeismicTrace.clearhistory
         myhist = t.history;
      end
      
      %% display functions - contained in external files
      disp(T)
      varargout = plot(T, varargin)
      linkedplot(T, alignTraces)
      varargout = legend(T, varargin)
   
      %% conversion functions
      function W = waveform(T)
         %waveform   convert SeismicTrace into waveform
         %   w = waveform(Trace) converts a SeismicTrace into a waveform.
         %   
         %  See also waveform, SeismicTrace
         
         W = repmat(waveform,size(T));
         for n=1:numel(T)
            W(n) = set(W(n),'channelinfo',T(n).channelinfo,...
               'freq', T(n).samplerate,...
               'data',T(n).data,...
               'units',T(n).units,...
               'start',T(n).firstsampletime);
            ufields = fieldnames(T(n).userdata);
            for z = 1:numel(ufields)
               W(n) = addfield(W(n), ufields{z}, T(n).userdata, T(n).userdata.(ufields{z}));
            end
         end
      end
      function CT = ChannelTag(T)
         %ChannelTag   Convert SeismicTrace into ChannelTag
         %   ct = ChannelTag(trace)
         %
         %   see also ChannelTag, SeismicTrace
         CT = reshape([T.channelinfo], size(T));
      end
   end
   methods(Static)
      function T = toTrace(item, itemlabel, conversionfunction)
         %toTrace   convert anything into traces
         % conversion functions exist outside SeismicTrace classdef so that
         % adding/removing/changing the conversion functions do not affect
         % this class
         % some envisioned examples
         % T = toTrace( X , 'fdsn_trace');
         % T = toTrace( X, 'fdsn_sac');
         % T = toTrace( X , 'winston');
         % T = toTrace( X , 'miniseed');
         % T = toTrace( X , 'seisan');
         % T = toTrace( X , 'seisan');
         % T = toTrace( X , 'waveform');
         
         %TODO: either flesh this out, or remove it
         
         persistent converters
         if isempty(converters)
            converters = [];
            %fill converters based on a directory/package
         end
      end
      
      function T = syntheticdata(names, starts, ends, samplerate)
         %syntheticdata   Crates a SeismicTrace filled with synthetic data
         %   T = syntheticdata(names, starts, ends, samplerate)
         %
         %   See also: randn, sin, SeismicTrace
         if ~exist('names','var') || isempty(names)
            names = 'NT.STA.LO.CHA'; end
         if ~exist('starts','var') || isempty(starts)
            starts = datenum([2015 09 23 15 45 0]);
         end
         if ~exist('ends','var') || isempty(ends)
            ends = starts + datenum([0 0 0 0 10 0]); % 10 minutes of data
         end
         if ~exist('samplerate','var') || isempty(samplerate)
            samplerate = 20;
         end
         warning('Creating a SeismicTrace using a noisy sine wave');
         if ischar(names)
            names = {names};
         end
         if ~exist('starts','var')
            % build T from names
         else
            T = SeismicTrace; 
            T.samplerate = samplerate;
            T = repmat(T, numel(names), numel(starts));
            
            for n=1:numel(names)
               [T(n,:).name] = deal(names(n));
            end
            for n=1:numel(starts)
               [T(:,n).start] = deal(starts(n));
               nSeconds = (ends(n) - starts(n)) * 86400;
               nsamples = nSeconds * samplerate;
               D = sin((-nsamples: 2 : nsamples-1) / 600) * 10 + randn(size(-nsamples: 2 : nsamples-1));
               [T(:,n).data] = deal(D);
            end
            % now fill with bogus data
         end
      end
      
      function T = retrieve(ds, names, starts, ends, miscfilters)
         %retrieve   Get a SeismicTrace from external data source
         %
         % UNDER CONSTRUCTION. for now, this is a wrapper around waveform.
         % it will use the waveform class to get data, and will then
         % convert to traces and pass that along.
         %
         % T = retrieve(datasouce, names, starts, ends, miscfilters)
         % names are channeltags OR N.S.L.C strings.
         % in future, this will be able to accept bulkdataselect (BDS)-type requests
         %    if BDS type, then starts, ends, miscfilters ignored.
         % for now
         % starts is either text, or array fo start times 
         % find data pointed to by ds, names, starts, ends
         % convertToTraces
         % return the traces
         
         if isa(names,'cell') || isa(names,'char')
            names = ChannelTag.array(names);
         end
         w = waveform(ds, names, starts, ends);
         T = SeismicTrace.waveform2trace(w);
      end
   end %static methods
end
