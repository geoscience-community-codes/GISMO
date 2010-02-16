function w = addfield(w,fieldname,value,noHistOption)
%ADDFIELD add fields and values to waveform object(s)                V1.1
%   waveform = addfield(waveform, fieldname, value)
%   This function creates a new user defined field, and fills it with the
%   included value.  If fieldname exists, it will overwrite the existing
%   value.
%
%   waveform = addfield(...'nohist') overrides history tracking
%
%   Input Arguments
%       WAVEFORM: a waveform object   N-DIMENSIONAL
%       FIELDNAME: a string name
%       VALUE: a value to be added for those fields.  Value can be anything
%
%   Starting with version 1.0, waveform objects can hold user-defined
%   fields.  To access the contents, use waveform/get, as you normally
%   would.
%
%   example:
%       w = waveform; %start with a blank waveform.
%       N = 1:45;     %create a variable containing the numbers 1-45
%       S = 'Thursday'; %create a string variable
%       C = {'first', 'second', N, S}; % create a cell aray with a variety
%                                      % of data
%
%       % add a field called "TESTFIELD", containing the numbers 1-45
%       w = addfield(w,'TestField',N);
%
%       % add another field called "MISHMOSH" containing the cell 'C'
%       w = addfield(w,'mishmosh',C);
%
%       disp(w) % results in the following output...
%            station: UNK
%            channel: EHZ
%              start: 01-Jan-1970 00:00:00.00
%                     duration(00:00:00.00)
%               data: 0 samples
%               freq: 100 Hz
%              units: counts
%             With misc fields...
%             * TESTFIELD: [1x45] double object
%             * MISHMOSH: [1x4] cell object
%
%
% See also WAVEFORM/SET, WAVEFORM/GET

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

useHistory = exist('noHistOption','var') && strcmpi(noHistOption,'nohist');
if isa(fieldname,'char')
  fieldname = {upper(fieldname)}; %convert to cell
else
  error('Waveform:addfield:invalidFieldname','fieldname must be a string')
end

actualfields = upper(fieldnames(w(1))); %get the object's intrinsic fieldnames

if ismember(fieldname,actualfields)
  if useHistory
    w = set(w, fieldname{1}, value); %set the value of the actual field
  else
    w = set(w, fieldname{1}, value,'nohist'); %set the value of the actual field
  end
  warning('Waveform:addfield:fieldExists',...
    'Attempted to add intrinsic field.\nNo field added, but Values changed anyway');
  return
end

% Fieldname isn't one that is intrinsic to the waveform object

for n=1:numel(w)                % for each possible waveform
  miscF = w(n).misc_fields;   % grab the misc_fields (cell of fieldnames)
  
  if ~any(strcmp(fieldname,miscF)) % if the field doesn't already exist...
    w(n).misc_fields = [miscF, fieldname]; %add the fieldname to the list
  end
  if useHistory
    w(n) = set(w(n), fieldname{1},value);
  else
    w(n) = set(w(n), fieldname{1},value,'nohist');
  end
end