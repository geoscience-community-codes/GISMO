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

%
for i=1:numel(properties.name)
  if ~isa(properties.name{i},'char')
    error('Waveform:parseargs:invalidPropertyName',...
      'All property names must be strings.');
  end
end