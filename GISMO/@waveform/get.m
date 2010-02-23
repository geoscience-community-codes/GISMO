function val = get(w,prop_name)
%GET Get waveform properties
%   val = get(waveform,prop_name)
%
%   Valid property names:
%       SCNLOBJECT, STATION, CHANNEL, NETWORK, LOCATION, FREQ, START_STR,
%       END_STR, DATA, NYQ, PERIOD 
%     also:
%       START, END : return datenum format (MatLab's format)
%       START_EPOCH, END_EPOCH : return epoch format.
%
%       DATA_LENGTH : return number of elements in data
%
%       The following return time duration of data
%       DURATION_STR :  text format
%       DURATION: matlab (datenum) format
%       DURATION_EPOCH : antelope (epoch) format (just # of seconds)
%
%       TIMEVECTOR : return a vector of same length as data with
%                    matlab-formatted times.
%
%       MISC_FIELDS: gets a list of fields that were added to this waveform
%       UNITS : Find out what units the data is in (ex. counts, nm/s)
%
%   If waveform is N-dimensional, then VAL will be a cell of the same
%   dimensions.  If GET would return single-values for the property, then
%   VAL will be a matrix of type DOUBLE, arranged in the same dimensions.
%
%       If additional fields were added to waveform using ADDFIELD, then
%       values from these can be retrieved using the fieldname
%
%       Example: Create a waveform, add a field, then get the field
%           W = waveform;
%           W = addfield(W,'P-pick', datenum('1/5/2007 02:12:15'));
%           misc = get(W,'MISC_FIELDS'); %returns a cell with 'P-pick'
%           PickTime = get(W,'P-pick'); % (same as) PickTime = get(W,misc);
%
%
%   See also WAVEFORM/GETM, WAVEFORM/SET, WAVEFORM/ADDFIELD,
%   WAVEFORM/DELFIELD

%  11/28/2008 added WAVEFORM_OBJECT_VERSION, which returns a single version
%  field from the waveform object.  This is set with the constructor, and
%  is used in load_obj.

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


%global mep2dep

val_CELL = cell(size(w));
val = val_CELL;
prop_name = upper(prop_name);

switch prop_name
  
  % IDENTIFICATION PROPERTIES
  case {'STATION','CHANNEL','NETWORK','LOCATION'} %type:CELL
    val = get([w.scnl],prop_name);
    
  case {'COMPONENT'} %type:CELL   GRANDFATHERED IN...
    val = get([w.scnl],'channel');
    
    % DATA DESCRIBING PROPERTIES
    
  case {'FS', 'FREQ'} %type:DOUBLE
    val = [w.Fs];
    
  case 'DATA' %type:DOUBLE
    val = {w.data}; %cells of data values
    
  case 'NYQ' %type:DOUBLE
    val = [w.Fs] ./ 2;
    
  case 'PERIOD' %type:DOUBLE
    val = 1 ./ [w.Fs];
    
  case 'DATA_LENGTH' %type:DOUBLE
    clear val
    for N = 1: numel(w)
      val(N) = numel(w(N).data);
    end
    
    % TIME PROPERTIES
    
  case {'START_STR'} %type:CELL
    val = stringDate([w.start]);
    
  case {'START_EPOCH'} %type:DOUBLE
    val = mep2dep([w.start]);
    
  case {'START_MATLAB', 'START'} %type:DOUBLE
    val = [w.start];
    
  case {'END_STR'} %type:CELL
    val = stringDate(grabEndTime(w));
    
  case {'END_EPOCH'} %type:DOUBLE
    val = mep2dep(grabEndTime(w));
    
  case {'END_MATLAB', 'END'} %type:DOUBLE
    val = grabEndTime(w);
    
  case {'DURATION_STR'} %type:CELL
    endvec = grabEndTime(w(:)) - [w(:).start];
    for N = 1 : numel(w)
      val(N) = {durationDate(endvec(N))};
    end
    
  case {'DURATION_EPOCH'} %type:DOUBLE
    val = (grabEndTime(w) - [w.start]) * 86400;
    %epoch time is # of seconds.
    
  case {'DURATION_MATLAB', 'DURATION'} %type:DOUBLE
    val = grabEndTime(w) - [w.start];
    
  case {'TIMEVECTOR'} %type:CELL
    for N = 1 : numel(w)
      Xvalues = linspace(w(N).start,get(w(N),'end'),length(w(N).data)+1);
      val{N} = Xvalues(1:end-1)';
    end
    
  case {'MISC_FIELDS'} %type:CELL
    val = {w.misc_fields};
    
  case {'UNITS'} %type : CELL
    val = {w.units};
  case {'WAVEFORM_OBJECT_VERSION'}
    val = w(1).version;
    
  case {'SCNLOBJECT'}
    val = [w.scnl];
    %must add network & location, too.
    
  case {'HISTORY'}
      val = cell(size(w));
      for n=1:numel(w)
          val(n) = {w(n).history};
      end
        
  otherwise
    %perhaps we're trying to get at one of the miscelleneous fields?
    for n = 1 : numel(w)
      %loc is the position...
      %w(n).misc_fields should ALWAYS already be in uppercase
      mask = strcmp(prop_name,w(n).misc_fields);
      %fieldwasfound = any(mask);
      %[fieldwasfound, loc] = ismember(prop_name, w(n).misc_fields);
      if any(mask)
          
        val{n} = w(n).misc_values{mask};
        %val{n} = w(n).misc_values{m};
      else
        warning('Waveform:get:unrecognizedProperty',...
          'Unrecognized property name : %s',  prop_name);
      end
    end
    %check to see if value can be returned as a numeric value instead
    %of cell.  Only if all values are numeric AND scalar
    numberize = true;
    for n=1:numel(val)
      if ~(isnumeric(val{n}) && isscalar(val{n}))
        numberize = false;
        break
      end
    end
    if numberize,
      Z = val;
      val = nan(size(Z));
      for n=1:numel(Z)
        val(n) = Z{n};
      end
    end
    
end;
if (numel(val) == numel(w)) %THIS TEST CONDITIONALIZED 4/16/2008
  val = reshape(val,size(w)); %return values in proper shape
end
if isscalar(w) && isa(val,'cell')
  val = val{1}; % return the actual value, not a cell array
end;

%%%%%%%%%%%%%%%%
function val = grabEndTime(w)
dlens = get(w,'data_length');
dlens = dlens(:);

myfrq = [w.Fs]; % get(w,'Freq');
myfrq = myfrq(:);

seclen = dlens ./ myfrq;

to_add = datenum([zeros(numel(w),5) seclen])';

svals = [w(:).start];
val = svals +  to_add;

%endvec = datevec([w.start]) + [0 0 0 0 0 length(w.data)/w.Fs];
%endvec = datevec([w.start]) + [0 0 0 0 0 get(w,'data_length') ./ get(w,'Freq')];
%val = datenum(endvec);

%%%%%%%%%%%%%%%%
function val = stringDate(myDate)
if isnan(myDate)
  warning('waveform:get:undefinedDate','Undefined date');
  val = 0;
  return
end
val = [datestr(myDate,'yyyy-mm-dd HH:MM:SS.FFF')];

%%%%%%%%%%%%%%%%
function val = durationDate(myDate)

if isnan(myDate)
  %this likely happened because the frequency was undefined (NaN)
  val = '';
  return;
end

myDate = myDate(:);
[yr mo da] = datevec(myDate);
val = '';
%if yr, val = [val sprintf('%2d years ',yr)]; end
%if mo, val = [val sprintf('%2d months ',mo)]; end
if (yr+mo+da)>1,
  val = [val sprintf('%4d days ',fix(myDate))];
end
val = [val datestr(myDate,'HH:MM:SS.FFF')];
