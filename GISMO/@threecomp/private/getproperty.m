function [isfound, foundvalue, properties] = getproperty(desiredproperty,properties,defaultvalue)
%GETPROPERTY returns a property value from a property list, or a default
%  value if none is available
%[isfound, foundvalue, properties] =
%      getproperty(desiredproperty,properties,defaultvalue) 
%
% returns a property value (if found) from a property list, removing that
% property pair from the list.  only removes the first encountered property
% name.
%
%see also waveform/private/parseargs, waveform/private/property2varargin

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