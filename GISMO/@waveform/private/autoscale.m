function newunit = autoscale(axishandle, oldunit)
% will automatically find the correct y-unites with which to plot something

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

if iscell(oldunit), oldunit = oldunit{1}; end;
ah = axishandle;
for n=numel(ah):-1:1
    miny(n) = min(get(ah(n),'ydata'));
    maxy(n) = max(get(ah(n),'ydata'));    
end
ydatamin = min(miny);
ydatamax = max(maxy);
knownunits = {'pm','nm','mm','cm','m','km'};
knownvals = 10.^[-12,-6,-3,-2,0,3];
biggest=  log10(max(abs([ydatamin, ydatamax])));
currentUnitIdx = find(strcmpi(oldunit(1:2),knownunits));
if isempty(currentUnitIdx),
  newunit= oldunit;
  return
end
%biggest_in_meters = biggest * knownvals(currentUnitIdx);
%convertFrom = knownvals(currentUnitIdx);
newUnitIdx = find(knownvals <= biggest*.1,1,'last');
canBeExpressedAs= knownunits(find(knownvals <= biggest*.1));
convertTo = canBeExpressedAs{end};
if numel(oldunit)>2
  newunit = [convertTo,oldunit(3:end)];
else
  newunit = convertTo;
end

set(ah,'ydata',get(ah,'ydata').*(knownvals(currentUnitIdx)./knownvals(newUnitIdx)));
