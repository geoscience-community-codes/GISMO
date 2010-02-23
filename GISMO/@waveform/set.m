function w = set(w, varargin)
%SET Set properties for waveform object(s)
%   w = Set(w,prop_name, val, [prop_name, val])
%   SET is one of the two gateway functions of an object, such as waveform.
%   Properties that are changed through SET are typechecked and otherwise
%   scrutinized before being stored within the waveform object.  This
%   ensures that the other waveform methods are all retrieving valid data,
%   thereby increasing the reliability of the code.
%
%   Another strong advantage to using SET and GET to change  and retrieve
%   properties, rather than just assigning them to the waveform directly,
%   is that the underlying data structure can change and grow without
%   harming the code that is written based on the waveform object.
%
%   Valid property names:
%
%       STATION, CHANNEL, FREQ, DATA, UNITS: self explanatory
%       START :         Set the start-time using matlab format or string
%       START_EPOCH:    Set the start-time using epoch (antelope) time
%       SAMPLE_LENGTH : adjusts the length of the data to length VAL.
%                       If this number is shorter than existing data, SET
%                       truncates after sample VAL.  If it is longer, then
%                       SET will pad the end with zeroes to get length VAL.
%
%       If user-defined fields were added to the waveform (ie, through
%       addField), these fieldnames are also available through set.
%
%       for example
%           % create a waveform object, and add a field called DUMMY with
%           % the value 12
%           w = addfield(waveform,'DUMMY',12);
%
%           % change the value of the DUMMY field
%           w = set(w,'DUMMY',32);
%
%           % change the station and channel at once
%           w = set(w,'Station','YCK', 'Channel', 'BHZ');
%
%   Batch changes can be made if input w is a matrix (use with care!)
%
%   NOTE: There is no set support for "version".  This is handled entirely
%         within the waveform constructor and the loadobj function.
%
% NOTE: To avoid logging the history, append the argument 'nohist'
%
%  See also WAVEFORM/GET

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: March 15, 2009

%4/22/08 added synonym for sample_length of data_length

%global dep2mep

% check to see if history is bypassed
UPDATE_HISTORY = ~strcmpi(varargin(end),'nohist');

Vidx = 1 : numel(varargin);

while numel(Vidx) >= 2
  prop_name = upper(varargin{Vidx(1)});
  val = varargin{Vidx(2)};
  
  %for n = 1 : numel(w);
  %out = w(n);
  
  switch prop_name
    case 'SCNLOBJECT'
      if isa(val,'scnlobject')
        
        [w.scnl] = deal(val);
      else
        error('Waveform:set:propertyTypeMismatch','Expected a SCNLOBJECT');
      end
      
    case {'STATION','NETWORK', 'CHANNEL','LOCATION'}
      if ~isa(val,'char')
        error('Waveform:set:propertyTypeMismatch',...
          '%s should be a string not a %s', prop_name,class(val));
      end
      allscnls = set([w.scnl],prop_name,val);
      for n=1:numel(w)
        w(n).scnl = allscnls(n);
      end
      
    case {'COMPONENT'} %grandfather case, supplanted by 'CHANNEL'
      if ~isa(val,'char')
        error('Waveform:set:propertyTypeMismatch',...
        'Channel should be a string not a %s', class(val));
      end
      for n=1:numel(w)
        w(n).scnl = set(w(n).scnl,'channel',val);
      end
      warning('Waveform:set:preferChannel',...
        ['Please use ''channel'' instead of ''component'''...
        '  no harm, no foul']);
      
      
    case {'FS', 'FREQ'}
      if ~isnumeric(val)
        error('Waveform:set:propertyTypeMismatch',...
          'Frequency should be numeric, not %s', class(val));
      end
      if numel(w)==1
          w.Fs = val(1);
      else
          [w.Fs] = deal(val(1));
      end
      
    case {'START', 'START_MATLAB'}
      %AUTOMATICALLY figures out whether date is antelope or matlab
      %format
      if ~(isnumeric(val) || isa(val,'char'))
        error('Waveform:set:propertyTypeMismatch',...
          'Start time not assigned... Unknown value type: %s', class(val));
      end
      if numel(w) == 1
          w.start = datenum(val);
      else
          [w.start] = deal(datenum(val));
      end
      
    case {'START_ANTELOPE', 'START_EPOCH'}
      if ~isnumeric(val),
        error('Waveform:set:propertyTypeMismatch',...
          'Epoch time should be numeric, not %s', class(val));
      end
      [w.start] = deal(datenum(dep2mep(val)));
      
    case 'DATA'
      if ~isnumeric(val)
        error('Waveform:set:propertyTypeMismatch',...
          'DATA should be numeric, not %s', class(val));
      end
      if numel(w) == 1
          w.data = val(:);
      else
          [w.data] = deal(val(:)); %always a column
      end
      
    case 'UNITS'
      if ~ischar(val)
        error('Waveform:set:propertyTypeMismatch',...
          'UNITS should be a string, not %s',class(val));
      end
      [w.units] = deal(val);
      
      
    case {'SAMPLE_LENGTH','DATA_LENGTH'} % chop data or zero pad to specific length
      if ~isnumeric(val),
        error('Waveform:set:propertyTypeMismatch',...
          'SAMPLE_LENGTH should be numeric, not %s',class(val));
      end
      for n=1:numel(w);
        if numel(w(n).data) >= val
          w(n).data = w(n).data(1:val,1);  % shrink the data
        else
          w(n).data(numel(w(n).data)+1 :val , 1) = 0; %zero pad
        end
      end
      
      case 'HISTORY'
          w = addhistory(w, val);
      
    otherwise
      for n=1:numel(w)
        switch prop_name
          case w(n).misc_fields
            %mask = ismember(w(n).misc_fields, prop_name);
            mask = strcmp(prop_name,w(n).misc_fields);
            w(n).misc_values(mask) = {val};
          otherwise
            error('Waveform:set:unknownProperty',...
              'can''t understand property name : %s', prop_name);
        end %switch
      end %n
  end %switch
  
  if ~strcmp(prop_name,{'HISTORY', 'DATA'}) & UPDATE_HISTORY
    
    w = addhistory(w,['Set ' prop_name]);
  end
  
  Vidx(1:2) = []; %done with those parameters, move to the next ones...
  
end;