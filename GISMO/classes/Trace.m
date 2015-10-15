classdef Trace < TraceData
   % Trace is the new waveform
   %
   % Unless otherwise stated, all work by Celso Reyes
   % Contributions by: Glenn Thompson, Michael West
   % Based on waveform, by Celso Reyes
   % XXXX by: 
   
   properties(Dependent)
      name % N.S.L.C code
      network % network code
      station % station code
      location % location code
      channel % channel code
      start % start time (text)
   end
   
   properties
      history = struct('what','created Trace','when',now); % history for Trace
      UserData = struct(); % structure containing user-defined fields
      calib = struct('value',1,'applied',false);
   end
   
   properties(Hidden)
      mat_starttime % start time in matlab-time
      channelinfo = channeltag; % channelTag
      %struct that mirrors UserData, but contains two fields:
      %   allowed_type: a class name (or empty). If this
      %   exist, then when data is assigned to UserData, it
      %   will be type-checked.
      %   min_count, max_count: if empty,any sized array can be
      %   assigned to this field.  If a single number, then
      %   eac assignment must have exactly this number of values.
      %   if [min max], then any number of values between min
      UserDataRules %   and max inclusive may be assigned to this.
   end
   
   properties(Hidden, Dependent)
   end
   
   methods
      function obj = Trace(varargin)
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
                        obj.UserData.(miscFields{n})= get(varargin{1},miscFields{n});
                     end
                  end
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
         %sampletimes retrieve matlab date for each sample
         % replaces get(w, 'timevector')
         val = sampletimes@TraceData(obj) + obj.mat_starttime;
      end
      
      function val = firstsampletime(obj, stringformat)
         % firstsampletime - get time of first sample as matlab date or string.
         % val = trace.lastsampletime will return as a datenum
         % val = trace.lastsampletime(FORMAT) will return a string
         % formatted according to FORMAT.
         % For multiple traces, a character array will be returned.
         %
         % see also datestr
         val = [obj.mat_starttime];
         if exist('stringformat','var')
            val = datestr(val,stringformat);
         end
      end
      function val = lastsampletime(obj, stringformat)
         % lastsampletime - get time of last sample as matlab date or string.
         % val = trace.lastsampletime will return as a datenum
         % val = trace.lastsampletime(FORMAT) will return a string
         % formatted according to FORMAT.
         %
         % For multiple traces, a character array will be returned.
         % see also datestr
         secDurs = [obj.duration];
         secDurs(secDurs > 0) = secDurs - [obj.samplerate];
         val = [obj.firstsampletime] + secDurs/86400;
         if exist('stringformat','var')
            val = datestr(val,stringformat);
         end
      end
         
      function tf = startsbefore(A, B)
         %TODO: make this work for datetime or datenums or datestrings
         tf = A.mat_starttime < B.mat_starttime;
      end
      function tf = startsafter(A, B)
         %TODO: make this work for datetime or datenums or datestrings
         tf = A.firstsampletime > B.firstsampletime;
      end
      function tf = endsbefore(A, B)
         %TODO: make this work for datetime or datenums or datestrings
         tf = A.lastsampletime < B.lastsampletime;
      end
      function tf = endsafter(A, B)
         %TODO: make this work for datetime or datenums or datestrings
         tf = A.lastsampletime > B.lastsampletime;
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
         T.channelinfo = channeltag(val);
      end
      
      function T = align(T,alignTime, newSamprate, method)
         %ALIGN resamples a waveform at over a specified interval
         %   w = w.align(alignTime, newSamprate)
         %   w = w.align(alignTime, newSamprate, method)
         %
         %   Input Arguments
         %       WAVEFORM: waveform object       N-dimensional
         %       ALIGNTIME: either a single matlab time or a series of times the
         %       same shape as the input TRACE matrix.
         %       newSamprate: sample rate (Samples per Second) of the newly aligned
         %          traces
         %       METHOD: Any of the methods from function INTERP
         %          If omitted, then the DEFAULT IS 'pchip'
         %
         %   Output
         %       The output waveform has the new samplerate newSamprate and a
         %       starttime calculated by the specified method, using matlab's
         %       INTERP1 function.
         %
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
         %   If used for particle motions, consider MatLab's plotmatrix command.
         %
         %   example:
         %   OUTDATED>    scnl = sclnobject('KDAK',{'BHZ','BHN','BHE'}); %grab all 3 channels
         %       % for each component, grab winston data on Kurile Earthquake
         %   OUTDATED>    w = waveform(mydatasource,scnl,'1/13/2007 04:20:00','1/13/2007 04:30:00');
         %       w = w.align('1/37/2007 4:22:00', w(1).samplerate);
         %
         %
         % See also INTERP1, PLOTMATRIX
         
         % AUTHOR: Celso Reyes
         
         oneSecond = 1/86400;
         
         if ~exist('method','var')
            method = 'pchip';
         end
         
         if ischar(alignTime),
            alignTime =  datenum(alignTime);
         end
         
         hasSingleAlignTime = numel(alignTime) == 1;
         
         if hasSingleAlignTime %use same align time for all waveforms
            alignTime = repmat(alignTime,size(T));
         elseif isvector(alignTime) && isvector(T)
            if numel(alignTime) ~= numel(T)
               error('Waveform:align:invalidAlignSize',...
                  'The number of Align Times does not match the number of waveforms');
            else
               % this situation OK.
               % ignore possibility that we're comparing a 1xN vs Nx1.
            end
         elseif ~all(size(alignTime) == size(T)) %make sure 1:1 ratio for alignTime & waveform
            if numel(alignTime) == numel(T)
               error('Waveform:align:invalidAlignSize',...
                  ['The alignTime matrix is of a different size than the '...
                  'waveform Matrix.  ']);
            end
         end
         
         
         newSamplesPerSec = 1 / newSamprate ;  %# samplesPerSecond
         timeStep = newSamplesPerSec * oneSecond;
         existingStarts = [T.mat_starttime]; %get(w,'start');
         existingEnds = get(T,'end');
         
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
         if hasSingleAlignTime
            % noteRealignment(w, alignTime(1), newSamprate);
         else
            for n=1:numel(T)
               % T(n) = noteRealignment(T(n), alignTime(n), newSamprate);
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
      % T.UserData = rmfield(T.UserData, 'fieldToDelete');
      
      % isfield is not implemented because matlab's can be used:
      % isfield(T.UserData,'something');
      
      function T = set.UserData(T, val)
         %sets UserData fields for a trace object
         % T.UserData.myfield = value;
         %
         % to impose constraings on the values that this field can
         % retrieve, use: Trace.SetUserDataRule(myfield,...)
         %
         % to delete the field:
         % T.UserData = rmfield(T.UserData, 'fieldToRemove');
         % see also Trace.SetUserDataRule, rmfield
         oldfields = fieldnames(T.UserData);
         fn = fieldnames(val);
         fieldToAdd = fn(~ismember(fn, oldfields));
         if ~isempty(fieldToAdd) && any(strcmpi(fieldToAdd, oldfields))
            % we have a case change!! uh-oh.
            error('attempted to add field [''%s''], but a similar field [''%s''] exists.\nCheck your case and try again',...
               fieldToAdd{1}, oldfields{strcmpi(oldfields, fieldToAdd)});
         end
         %fn_existing = fieldnames(T.UserData);
         %newfn = ~ismember(fieldnames(val),val
         for f = 1:numel(fn);
            testUserField(T, fn{f}, val.(fn{f}))
         end
         T.UserData = val;
      end
      
      function T = renameUserField(T, oldField, newField, failSilently)
         % Trace.renameUserField renames a UserData field
         % T = T.renameuserField(oldName, newName);
         % rename a field if it exists to a new name.
         % Possible sticking-points to deal with:
         % 1. both oldField and newField exist in T.UserData -> error
         % 2. newField already exists in T.UserData -> ignore
         % 3. neither newField or oldfield exists in T.Userdata -> warning
         % 
         % if failSilently is true, then failures will not result in an
         % error.
         oldFieldExists = isfield(T.UserData, oldField);
         newFieldExists = isfield(T.UserData, newField);
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
                  error('Both fields already exist, and UserData.%s already contains data',newField);
               else % but the new one is empty, so proceed normally
                  if ~failSilently
                     warning('Both fields exist, but since UserData.%s is empty, its value is being replaced', newField);
                  end
                  tmp = T.UserData.(oldField);
                  T.UserData = rmfield(T.UserData,oldField);
                  [T.UserData.(newField)] = tmp;
               end
            else % only the old field exists, so proceed normally
               tmp = T.UserData.(oldField);
               T.UserData = rmfield(T.UserData,oldField);
               [T.UserData.(newField)] = tmp;
            end
         else
            if newFieldExists  %only the new field exists
               % already renamed. ignore
            else % neither field exists
               if ~failSilently
                 warning('field [%s] does not exist in UserData', oldField);
               end
            end
         end
      end
      
      function testUserField(obj, fn, value)
         if ~isfield(obj.UserDataRules,fn)
            return;
         end
         if ~isfield(obj.UserData,fn)
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
            value = obj.UserData.(fn);
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
         % setUserDataRule creates rules that govern setting various userdata fields.
         % T = T.setUserData(fieldname, classname) will have the class
         % checked each time a value is assigned to the UserData
         % field T.UserData.fieldname.
         %
         % T = T.setUserDataRule(fieldname, classname, count) controls the
         % array size for any assignments to T.UserData.fieldname.  count
         % may be a single number N or a range [nMin nMax]
         % for any value assigned to T.UserData.fieldname,
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
         % assignments to T.UserData.code will be a string between 1 and 4
         % characters in length.
         %
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
         %TODO: Make this TRACE-y. which involves sorting by User fields
         %too.
         %
         % sortby sorts waveforms based on one of its properties
         %
         % Wsorted = sortby(Win) sorts by the channeltag (N.S.L.C)
         %
         % Wsorted = sortby(Win, criteria), where criteria is a valid "get"
         % request.  ex. starttime, endtime, channelinfo, freq, data_length, etc.
         %
         % [Wsorted, I] = sortby(Win...) will also return the index list so that
         %     Win(I) = Wsorted
         %
         % see also: sort, waveform/get
         
         if nargin < 2
            criteria = 'channeltag';
         end
         % sort by a field
         [~, I] = sort(get(T,criteria));
         T = T(I);
      end

      function combined_traces = combine (traces)
         %TODO: remove references to scnl, and replace with channeltag
         %COMBINE merges waveforms based on start/end times and channeltag info.
         % combined_waveforms = combine (waveformlist) takes a vector of waveforms
         % and combines them based on SCNL information and start/endtimes.
         % DOES NO OTHER CHECKS
         
         % AUTHOR: Celso Reyes
         
         if numel(traces) == 0  %nothing to do
            combined_traces = traces;
            return
         end
         
         channelinfo = get(traces,'channeltag');
         [uniquescnls, idx, scnlmembers] = unique(channelinfo);
         
         %preallocate
         combined_traces = repmat(waveform,size(uniquescnls));
         
         for i=1:numel(uniquescnls)
            T = traces(scnlmembers == i);
            T = timesort(T);
            for j=(numel(T)-1):-1:1
               T(j) = piece_together(T(j), T(j+1));
               T(j+1) = [];
            end
            combined_traces(i) = T;
         end
         
         function Tout = piece_together(T1, T2)
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
         
         function T1 = spliceAndPad(T1, T2, paddingAmount)
            if paddingAmount > 0 && ~isinf(paddingAmount)
               toAdd = nan(paddingAmount,1);
            else
               toAdd = [];
            end
            
            T1.data = [T1.data; toAdd; T2.data];
         end
         
         function T1 = spliceTrace(T1, T2)
            timesToGrab = sum(T1.sampletimes < T2.mat_starttime);
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
      
      function outW = extract(w, method, startV, endV)
         %TODO: make this Trace-y.  This is currently written for waveforms
         %TODO: Decide on proper wording! Should this be multiple functions?
         %EXTRACT creates a waveform with a subset of another's data.
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
         %         % note, 25 peices. equivelent to 0:1:24, including both midnights
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
         %   See also WAVEFORM/SET -- Sample_Length
         
         % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
         
         %% Set up condition variables, and ensure validity of input
         MULTIPLE_WAVES = ~isscalar(w);
         
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
            w = w(:);
         end
         
         %%
         if numel(w)==0 || numel(startV) ==0
            warning('Waveform:extract:emptyWaveform','no waveforms to extract');
            return
         end
         outW(numel(w),numel(startV)) = waveform;
         
         for m = 1: numel(startV) %loop through the number of extractions
            for n=1:numel(w); %loop through the waveforms
               inW = w(n);
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
                        [myStartI myStartTime] = time2offset(inW,startV(m));
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
                     sampTimes = get(inW,'timevector'); % grab individual sample times
                     myStart = sampTimes(startV(m));
                     
                  case 'index&duration'
                     % startV is an index into the data, endV is a matlab date
                     myData = myData(startV(m):end); %grab the data starting at our index
                     
                     sampTimes = get(inW,'timevector'); % grab individual sample times
                     sampTimes = sampTimes(startV(m):end); % truncate to match data
                     
                     myStart = sampTimes(1); %grab our starting date before hacking it
                     
                     sampTimes = sampTimes - sampTimes(1); %set first time to zero
                     count = sum(sampTimes <= endV(m)) -1;
                     myData = myData(1:count);
                     
                     
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
                  outW(n,m) = set(inW,'start',myStart, 'data', myData);
               else
                  outW(n) = set(inW,'start',myStart, 'data', myData);
               end
            end % n-loop (looping through waveforms)
         end % m-loop (looping through extractions)
         
         function  [B,A] = swap(A,B)
            %do nothing, just flip inputs & outputs
         end
      end
      
      %function ismember
      %function isvertical (?) don't like this.
      
      %function calib_apply
      %function calib_remove
      
      %% history-related functions
      function T = addhistory(T, whathappened,varargin)
         %ADDHISTORY function in charge of adding history to a waveform
         %   trace = trace.addhistory(whathappened);
         %   trace = trace.addhistory(formatString, [variables...])
         %
         %   The second way of using addhistory follows the syntax of fprintf
         %
         %   Input Arguments
         %       WAVEFORM: a Trace object
         %       WHATHAPPENED: absolutely anything.  Really.
         %
         %   AddHistory appends not only what happened, but also keeps track of WHEN
         %   it happened.
         %
         %   example
         %       T = Trace; %create a blank trace
         %       T = T.addhistory('the following procedures done by DoIt.m');
         %       N = 1; M = 'Today'
         %       T = T.addhistory('this is sample #%d date:%s',N,M);
         %       % what is actually added: "this is sample #1 date:Today"
         %
         % See also Trace.history, fprintf
         
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
         %CLEARHISTORY reset history of a waveform
         %   trace = trace.clearhistory
         %   clears the history, leaving it blank
         %
         % See also Trace.addhistory Trace.history.         
         T(N).history= T(N).history([]);
      end
      function [myhist] = get.history(w)
         %HISTORY retrieve the history of a waveform object
         %   myhist = history(waveform)
         %       returns a struct describing what's been done to this trace
         %
         % See also Trace.addhistory, Trace.clearhistory
         if numel(w) > 1
            error('Waveform:history:tooManyWaveforms',...
               '''waveform/history()'' can only retrieve history for individual waveforms');
         end
         myhist = w.history;
      end
      
      %% display functions
      function disp(w)
         %DISP Trace disp overloaded operator
         
         
         % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
         % $Date$
         % $Revision$
         
         if numel(w) > 1;
            disp(' ');
            fprintf('[%s] %s containing:\n', size2str(size(w)), class(w));
            % could present fields that it has in common
            %could provide a bulkdataselect style output...
            fprintf('net.sta.lo.cha\tfirstsample\t\t  nsamples\tsamprate\t duration\n');
            for n=1:numel(w)
            secs = mod(w(n).duration,60);
            mins = mod(fix(w(n).duration / 60),60);
            hrs = fix(w(n).duration / 3600);
               fprintf('%-10s\t%s\t%9d\t%9.3f\t',...
                  w(n).name, w(n).start, numel(w(n).data), w(n).samplerate); 
               fprintf('%02d:%02d:%05.3f\n' , hrs,mins,secs);
            end;
            return
               U = unique({w.name});
            if numel(U) < 5
               for n=1:numel(U)
                  fprintf('    %s\n', U{n});
               end
            else
               fprintf('     %d unique net.sta.loc.cha combos\n',numel(U));
            end
            % starting ranges
            % duration ranges
            % sample ranges
            %samplerate ranges
            
         elseif numel(w) == 0
            disp('  No Traces');
            
         else %single Trace
            % no longer have test for complete/empty waveform
            fprintf(' channeltag: %-15s   [network.station.location.channel]\n', w.name);
            fprintf('      start: %s\n',w.start);
            secs = mod(w.duration,60);
            mins = mod(fix(w.duration / 60),60);
            hrs = fix(w.duration / 3600);
            fprintf('             duration %02d:%02d:%06.3f\n' , hrs,mins,secs);
            fprintf('       data: %d samples\n', numel(w.data));
            fprintf('             range(%f, %f),  mean (%f)\n',min(w), max(w), mean(w));
            fprintf('sample rate: %-10.4f samples per sec\n',w.samplerate);
            fprintf('      units: %s\n',w.units);
            historycount =  numel(w.history);
            if historycount == 1
               plural='';
            else
               plural = 's';
            end
            fprintf('    history: [%d item%s], last modification: %s\n',...
               historycount, plural, datestr(max([w.history.when])));
            ud_fields = fieldnames(w.UserData);
            if isempty(ud_fields)
               disp('<No user defined fields>');
            else
            fprintf('User Defined fields:\n');
            for n=1:numel(ud_fields);
               if isstruct(w.UserDataRules) && isfield(w.UserDataRules, ud_fields{n})
                  fprintf('   *%-15s: ',ud_fields{n}); disp(w.UserData.(ud_fields{n}));
               else
                  fprintf('    %-15s: ',ud_fields{n}); disp(w.UserData.(ud_fields{n}));
               end
            end
            disp(' <(*) before fieldname means that rules have been set up governing data input for this field>');
            end
         end
         
         function DispStr = size2str(sizeval)
            % helper function that changes the way we view the size
            %   from : [1 43 2 6] (numeric)  to  '1x43x2x6' (char)
            
            DispStr = sprintf('x%d', sizeval);
            DispStr = DispStr(2:end);
         end
      end
      
      %% plotting functions
      function varargout = plot(T, varargin)
         %TODO: use parse
         %PLOT plots a waveform object
         %   h = plot(trace)
         %   Plots a waveform object, handling the title and axis labeling.  The
         %      output parameter h is optional.  If u, thto the waveform
         %   plots will be returned.  These can be used to change properties of the
         %   plotted waveforms.
         %
         %   h = trace.plot(...)
         %   Plots a waveform object, passing additional parameters to matlab's PLOT
         %   routine.
         %
         %   h = trace.plot('xunit', xvalue, ...)
         %   sets the xunit property of the graph, which is used to determine how
         %   the times of the waveform are interpereted.  Possible values for XVALUE
         %   are 's', 'm', 'h', 'd', 'doy', 'date'.
         %
         %        'seconds' - seconds
         %        'minutes' - minutes
         %        'hours' - hours
         %        'day_of_year' - day of year
         %        'date' - full date
         %
         %   for multiple waveforms, specifying XUNITs of 's', 'm', and 'h' will
         %   cause all the waveforms to be plotted starting at 0.  An XUNIT of
         %   'date' will force all waveforms to plot starting at their starttimes.
         %
         %   the default XUNIT is seconds
         %
         %  For the following examples:
         %  % W is a waveform, and W2 is a smaller waveform (from within W)
         %  W = waveform('SSLN','SHZ','04/02/2005 01:00:00', '04/02/2005 01:10:00');
         %  W2 = extract(W,'date','04/02/2005 01:06:10','04/02/2005 01:06:33');
         %
         % EXAMPLE 1:
         %   % This example plots the waveforms at their absolute times...
         %   W.plot('xunit','date'); % plots the waveform in blue
         %   hold on;
         %   h = W2.plot('xunit','date', 'r', 'linewidth', 1);
         %          %plots your other waveform in red, and with a wider line
         %
         % EXAMPLE 2:
         %   % This example plots the waveforms, starting at time 0
         %   W.plot(); % plots the waveform in blue with seconds on the x axis
         %   hold on;
         %   W2.plot('xunit','s', 'color', [.5 .5 .5]);  % plots your other
         %                                       % waveform, starting in unison
         %                                       % with the prev waveform, then
         %                                       % change the color of the new
         %                                       % plot to grey (RGB)
         %
         %  For a list of properties you can set (such as color, linestyle, etc...)
         %  type get(h) after plotting something.
         %
         %  also, now Y can be autoscaled with the property pair: 'autoscale',true
         %  although it only works for single waveforms...
         %
         %  see also DATETICK, Trace.plot, PLOT
         
         % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
         %
         % modified 11/17/2008 by Jason Amundson (amundson@gi.alaska.edu) to allow
         % for "day of year" flag
         %
         % 11/25/2008 changed how parameters are parsed, fixing a bug where you
         % could not specify both an Xunit and a plot-style ('.', for example)
         %
         % individual sample rates used instead of assumed to be equal
         
         
         if isscalar(T),
            yunit = T.units;
         else
            yunit = arrayfun(@(tr) tr.units, T, 'UniformOutput',false); %
            yunit = unique(yunit);
         end
         
         %Look for an odd number of arguments beyond the first.  If there are an odd
         %number, then it is expected that the first argument is the formatting
         %string.
         [formString, proplist] = getformatstring(varargin);
         hasExtraArg = ~isempty(formString);
         [isfound, useAutoscale, proplist] = getproperty('autoscale',proplist,false);
         [isfound, xunit, proplist] = getproperty('xunit',proplist,'s');
         [isfound, currFontSize, proplist] = getproperty('fontsize',proplist,10);
         
         [xunit, xfactor] = parse_xunit(xunit);
         
         switch lower(xunit)
            case 'date'
               % we need the actual times...
               for n=1:numel(T)
                  tv(n) = {T(n).sampletimes};
               end
               % preAllocate Xvalues
               tvl = zeros(size(tv));
               for n=1:numel(tv)
                  tvl(n) = numel(tv{n}); %tvl : TimeVectorLength
               end
               
               Xvalues = nan(max(tvl),numel(T)); %fill empties with NaN (no plot)
               
               for n=1:numel(tv)
                  Xvalues(1:tvl(n),n) = tv{n};
               end
               
               
            case 'day of year'
               allstarts = [T.mat_starttime];
               startvec = datevec(allstarts(:));
               dec31 = datenum([startvec(1)-1,12,31,0,0,0]); % 12/31/xxxx of previous year in Matlab format
               startdoy = datenum(allstarts(:)) - dec31;
               
               dl = zeros(size(T));
               for n=1:numel(T)
                  dl(n) = numel(T(n).data); %dl : DataLength
               end
               
               Xvalues = nan(max(dl),numel(T));
               
               samprates = [T.samplerate];
               for n=1:numel(T)
                  Xvalues(1:dl(n),n) = (1:dl(n))./ samprates(n) ./ ...
                     xfactor + startdoy(n) - 1./samprates(n)./xfactor;
               end
               
            otherwise,
               longest = max(arrayfun(@(tr) numel(tr.data), T));
               Xvalues = nan(longest, numel(T));
               for n=1:numel(T)
                  dl = numel(T(n).data);
                  Xvalues(1:dl,n) = (1:dl) ./ T(n).samplerate ./ xfactor;
               end
         end
         
         if hasExtraArg
            varargin = [varargin(1),property2varargin(proplist)];
         else
            varargin = property2varargin(proplist);
         end
         % %
         
         h = plot(Xvalues, double(T,'nan') , varargin{:} );
         
         if useAutoscale
            yunit = autoscale(h, yunit);
         end
         
         yh = ylabel(yunit,'fontsize',currFontSize);
         
         xh = xlabel(xunit,'fontsize',currFontSize);
         switch lower(xunit)
            case 'date'
               datetick('keepticks','keeplimits');
         end
         if isscalar(T)
            th = title(sprintf('%s (%s) @ %3.2f samp/sec',...
               T.name, T.start, T.samplerate),'interpreter','none');
         else
            th = title(sprintf('Multiple Traces.  wave(1) = %s (%s) - starting %s',...
               T(1).station, T(1).channel, T(1).start),'interpreter','none');
         end;
         
         
         
         set(th,'fontsize',currFontSize);
         set(gca,'fontsize',currFontSize);
         %% return the graphics handles if desired
         if nargout >= 1,
            varargout(1) = {h};
         end
         
         % return additional information in a structure: when varargout ==2
         plothandles.title = th;
         plothandles.xunits = xh;
         plothandles.yunits = yh;
         if nargout ==2,
            varargout(2) = {plothandles};
         end
         
         function [isfound, foundvalue, properties] = getproperty(desiredproperty,properties,defaultvalue)
            %GETPROPERTY returns a property value from a property list, or a default
            %  value if none is available
            %[isfound, foundvalue, properties] =
            %      getproperty(desiredproperty,properties,defaultvalue)
            %
            % returns a property value (if found) from a property list, removing that
            % property pair from the list.  only removes the first encountered property
            % name.
            
            pmask = strcmpi(desiredproperty,properties.name);
            isfound = any(pmask);
            if isfound
               foundlist = find(pmask);
               foundidx = foundlist(1);
               foundvalue = properties.val{foundidx};
               properties.name(foundidx) = [];
               properties.val(foundidx) = [];
            else
               if exist('defaultvalue','var')
                  foundvalue = defaultvalue;
               else
                  foundvalue = [];
               end
               % do nothing to properties...
            end
         end
         
         function [formString, proplist] = getformatstring(arglist)
            hasExtraArg = mod(numel(arglist),2);
            if hasExtraArg
               proplist =  parseargs(arglist(2:end));
               formString = arglist{1};
            else
               proplist =  parseargs(arglist);
               formString = '';
            end
         end
         
         function c = property2varargin(properties)
            %PROPERTY2VARARGIN makes a cell array from properties
            %  c = property2varargin(properties)
            % properties is a structure with fields "name" and "val"
            c = {};
            c(1:2:numel(properties.name)*2) = properties.name;
            c(2:2:numel(properties.name)*2) = properties.val;
         end
         function [properties] = parseargs(arglist)
            % PARSEARGS creates a structure of parameternames and values from arglist
            %  [properties] = parseargs(arglist)
            % parse the incoming arguments, returning a cell with each parameter name
            % as well as a cell for each parameter value pair.  parseargs will also
            % doublecheck to ensure that all pnames are actually strings... otherwise,
            % there will be a mis-parse.
            %check to make sure these are name-value pairs
            %
            % see also waveform/private/getproperty, waveform/private/property2varargin
            
            argcount = numel(arglist);
            evenArgumentCount = mod(argcount,2) == 0;
            if ~evenArgumentCount
               error('Waveform:parseargs:propertyMismatch',...
                  'Odd number of arguments means that these arguments cannot be parameter name-value pairs');
            end
            
            %assign these to output variables
            properties.name = arglist(1:2:argcount);
            properties.val = arglist(2:2:argcount);
            
            for i=1:numel(properties.name)
               if ~ischar(properties.name{i})
                  error('Waveform:parseargs:invalidPropertyName',...
                     'All property names must be strings.');
               end
            end
         end
         function [unitName, secondMultiplier] = parse_xunit(unitName)
            % PARSE_XUNIT returns a labelname and a multiplier for an incoming xunit
            % value.  This routine was removed to centralize this function
            % [unitName, secondMultiplier] = parse_xunit(unitName)
            secsPerMinute = 60;
            secsPerHour = 3600;
            secsPerDay = 3600*24;
            
            switch lower(unitName)
               case {'m','minutes'}
                  unitName = 'Minutes';
                  secondMultiplier = secsPerMinute;
               case {'h','hours'}
                  unitName = 'Hours';
                  secondMultiplier = secsPerHour;
               case {'d','days'}
                  unitName = 'Days';
                  secondMultiplier = secsPerDay;
               case {'doy','day_of_year'}
                  unitName = 'Day of Year';
                  secondMultiplier = secsPerDay;
               case 'date',
                  unitName = 'Date';
                  secondMultiplier = nan; %inconsequential!
               case {'s','seconds'}
                  unitName = 'Seconds';
                  secondMultiplier = 1;
                  
               otherwise,
                  unitName = 'Seconds';
                  secondMultiplier = 1;
            end
         end
      end %plot
      
      function linkedplot(T, alignTraces)
         %LINKEDPLOT Plot multiple waveform objects as separate linked panels
         %   linkedplot(trace, alignTraces)
         %   where:
         %       T = a vector of Trace
         %       alignWaveforms is either true or false (default)
         %   T.linkedplot will plot a record section, i.e. each waveform is plotted
         %   against absolute time.
         %   T.linkedplot(true) will align the waveforms on their start times.
         
         % Glenn Thompson 2014/11/05, generalized after a function I wrote in 2000
         % to operate on Seisan files only
         
         if numel(T)==0
            warning('no waveforms to plot')
            return
         end
         
         if ~exist('alignWaveforms', 'var')
            alignTraces = false;
         end
         
         % get the first start time and last end time
         starttimes = [T.mat_starttime];
         % endtimes = T.timeLastSample();
         SECSPERDAY = 86400;
         grabendtime = @(X) (X.mat_starttime + (numel(X.data)-1) / (X.samplerate * SECSPERDAY));
         endtimes = arrayfun(grabendtime, T);
         endtimes(endtimes < starttimes) = starttimes(endtimes<starttimes); %no negative values!
         % [starttimes endtimes]=gettimerange(T);
         snum = min(starttimes(~isnan(starttimes)));
         enum = max(endtimes(~isnan(endtimes)));
         
         % get the longest duration - in mode=='align'
         durations = endtimes - starttimes;
         maxduration = max(durations(~isnan(durations)));
         
         nwaveforms = numel(T);
         figure
         trace_height=0.9/nwaveforms;
         left=0.1;
         width=0.8;
         for wavnum = 1:nwaveforms
            myw = T(wavnum);
            dnum = myw.sampletimes;
            ax(wavnum) = axes('Position',[left 0.95-wavnum*trace_height width trace_height]);
            if alignTraces
               plot((dnum-min(dnum))*SECSPERDAY, myw.data,'-k');
               set(gca, 'XLim', [0 maxduration*SECSPERDAY]);
            else
               plot((dnum-snum)*SECSPERDAY, myw.data,'-k');
               set(gca, 'XLim', [0 enum-snum]*SECSPERDAY);
            end
            ylabel(myw.channelinfo.string,'FontSize',10,'Rotation',90);
            set(gca,'YTick',[],'YTickLabel','');
            if wavnum<nwaveforms;
               set(gca,'XTickLabel','');
            end
            
            % display mean on left, max on right
            text(0.02,0.85, sprintf('%5.0f',mean(abs(myw.data(~isnan(myw.data))))),'FontSize',10,'Color','b','units','normalized');
            text(0.4,0.85,sprintf(' %s',datestr(starttimes(wavnum),30)),'FontSize',10,'Color','g','units','normalized');
            text(0.9,0.85,sprintf('%5.0f',max(abs(myw.data(~isnan(myw.data))))),'FontSize',10,'Color','r','units','normalized');
         end
         
         if exist('ax','var')
            linkaxes(ax,'x');
         end
         
         originalXticks = get(gca,'XTickLabel');
         
         f = uimenu('Label','X-Ticks');
         uimenu(f,'Label','time range','Callback',{@daterange, snum, SECSPERDAY});
         uimenu(f,'Label','quit','Callback','disp(''exit'')',...
            'Separator','on','Accelerator','Q');
         
         function daterange(obj, evt, snum, SECSPERDAY)
            xlim = get(gca, 'xlim');
            xticks = linspace(xlim(1), xlim(2), 11);
            mydate = snum + xlim/SECSPERDAY;
            datestr(mydate,'yyyy-mm-dd HH:MM:SS.FFF')
         end
      end
      
      %%
      function varargout = legend(T, varargin)
         %TODO: FIX REPETITIONS
         %legend creates a legend for a waveform graph
         %  legend(traces) attempts to automatically create a legend based upon
         %  unique values within the waveforms.  in order, the legend will
         %  preferentially use station, channel, start time.
         %
         %  legend(traces, field1, [field2, [..., fieldn]]) will create a legend,
         %  using the fieldnames.
         %
         %  h = legend(...) returns the handle for the created legend.  this handle
         %  can be used to later modify the legend entry (such as setting the
         %  location, etc.)
         %
         %  Note: for additional control, use matlab's legend function by passing it
         %  cells & strings instead of a waveform.
         %    (hint:useful functions include waveform/get, strcat, sprintf, num2str)
         %
         %  see also legend
         
         if nargin == 1
            % automatically determine the legend
            total_waves = numel(T);
            cha_tags = [T.channelinfo];
            ncha_tags = numel(unique(cha_tags));
            if ncha_tags == 1
               % all cha_tags represent the same station
               items = T.start;
            else
               uniquestations = unique({cha_tags.station});
               stationsareunique = numel(uniquestations) == total_waves;
               issinglestation = isscalar(uniquestations);
               
               uniquechannels = unique({cha_tags.channel});
               channelsareunique = numel(uniquechannels) == total_waves;
               issinglechannel = isscalar(uniquechannels);
               
               if stationsareunique
                  if issinglechannel
                     items = {cha_tags.station};
                  else
                     items = strcat({cha_tags.station},':',{cha_tags.channel});
                  end
               elseif issinglestation
                  if issinglechannel
                     items = T.start;
                  elseif channelsareunique
                     items = {cha_tags.channel};
                  else
                     % 1 station, mixed channels
                     items = strcat({cha_tags.channel},': ',T.start);
                  end
               else %mixed stations
                  if issinglechannel
                     items = strcat({cha_tags.station},': ',T.start);
                  else
                     items = strcat({cha_tags.station},':', {cha_tags.channel});
                  end
               end
               
            end
            
            
            
         else
            %let the provided fieldnames determine the legend.
            items = T.(varargin{1});
            items = anything2textCell(items);
            
            for n = 2:nargin-1
               nextitems = T.(varargin{n});
               items = strcat(items,':',anything2textCell(nextitems));
            end
         end
         
         h = legend(items);
         if nargout == 1
            varargout = {h};
         end
         
         function stuff = anything2textCell(stuff)
            %convert anything to a text cell
            if isnumeric(stuff)
               stuff=num2str(stuff);
            elseif iscell(stuff)
               if isnumeric(stuff{1})
                  for m=1 : numel(stuff)
                     stuff(m) = {num2str(stuff{m})};
                  end
               end
            end
         end
      end
      
   end
   methods(Static)
      function T = waveform2trace(W)
         % convert waveforms into traces
         assert(isa(W,'waveform'));
         for N=1:numel(W)
            T(N) = Trace(W(N));
         end
      end
      function W = trace2waveform(T)
         % convert traces into waveforms
         error('not implemented yet')
      end
   end %static methods
end
