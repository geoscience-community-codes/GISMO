function w = delfield(w,field_to_delete, nohistory)
%DELFIELD removes fields from waveform object(s)
%   w = delfield(waveform, fieldname)
%       if a user-defined field exists whose name matches the string within
%       FIELDNAME exists, then it will be deleted from the waveform(s).
%       This will not remove fields intrinsic to the waveform object.
%
%   Input Arguments
%       WAVEFORM: a waveform object    N-DIMENSIONAL
%       FIELDNAME: case insensitive string name of the field to delete.
%
%   See also WAVEFORM/ADDFIELD, WAVEFORM/GET -- 'misc_fields'

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 9/2/2009 - added option to override history

if isa(field_to_delete,'char')
    field_to_delete = {upper(field_to_delete)}; %convert to cell
else
    if isempty(field_to_delete)
        warning('Waveform:delfield:emptyFieldName','empty field name')
        return
    else
        error('Waveform:delfield:invalidFieldName',...
          'fieldname must be a string, not a %s', class(field_to_delete));
    end
end

for n=1:numel(w)
    miscF = w(n).misc_fields;
    mask = ~ismember(miscF, field_to_delete);
    w(n).misc_fields = w(n).misc_fields(mask);
    w(n).misc_values = w(n).misc_values(mask);
end

if ~exist('nohistory','var') || ~nohistory
  w = addhistory(w,['Removed Field: ' field_to_delete{:}]);
end
