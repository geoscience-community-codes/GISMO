function TF = isfield(w,testField)
%ISFIELD checks the presence of waveform fields.
%   TF = ISFIELD(WAVEFORM,FIELD) returns an array the same size as
%   WAVEFORM, containing logical 1 (true) where the elements of WAVEFORM
%   contains the field specified by FIELD, and logical 0 (false) elsewhere.
%   This is valuable since waveforms are capable of storing arbitrary
%   user-defined fields. WAVEFORM can be of arbitrary size. FIELD may be a
%   character string of a cell containing the same.
%
%   TF = ISFIELD(WAVEFORM,{FIELD1 FIELD2 FIELD3 ...}) checks for presence
%   of several fields. In this use, WAVEFORM must be 1x1. TF is a matrix of
%   logical 0 or 1 (true or false) with one element for each input FIELD.
%   FIELD must be a cell array containing character strings.
%
%  See also ADDFIELD

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% READ & CHECK ARGUMENTS
if (nargin~=2)
    error('Incorrect number of arguments');
end
if ~isa(w,'waveform')
    error('First input must be a waveform object');
end
if ~isa(testField,'char') && ~isa(testField,'cell')
    error('Second argument must be a string or cell array of strings');
end
if isa(testField,'char')
    testField = {testField};
end
if numel(w)>1 && numel(testField)>1
    error('Multiple waveforms can only be tested against a single field at a time');
end


% GET LIST(S) OF STANDARD PLUS MISC. FIELDS
if numel(w)==1
    waveformMiscFields = {get(w,'MISC_FIELDS')};
else
    waveformMiscFields = get(w,'MISC_FIELDS');
end
waveformStandardFields = fields(waveform)';
waveformFields = cell(size(w));
for n = 1:numel(waveformFields)
    waveformFields{n} = [waveformStandardFields waveformMiscFields{n}];
end


% TEST AGAINST A SINGLE FIELD
if numel(testField)==1
    TF = zeros(size(w));
    for n = 1:numel(TF)
        TF(n) = max(strcmpi(testField,waveformFields{n}));
    end
end


% TEST AGAINST MULTIPLE FIELDS
if numel(testField)>1
    TF = zeros(size(testField));
    for n = 1:numel(TF)
        TF(n) = max(strcmpi(testField(n),waveformFields{1}));
    end
    
end