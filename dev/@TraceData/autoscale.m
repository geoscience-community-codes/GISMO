function newunit = autoscale(axishandle, oldunit)
   %autoscale   automatically determine correct y-units for plotting
   %  newunit = autoscale(axishandle, oldunit) autoscales the data in an
   %  axis by considering its range and units, then determines a new unit.
   
   %TODO: (maybe) make this TraceData dependent, and not axis dependent.
   
   if iscell(oldunit), oldunit = oldunit{1}; end;
   ah = axishandle;
   
   % yRange = @(ax) max(get(ax,'ydata')) - min(get(ax,'ydata'));
   % yMaxrange = max(arrayfun(yRange,ah)); % greatest data range from axis
   
   yFarthestFrom0 = @(ax) max(abs(get(ax,'ydata')));
   ydatamax = max(arrayfun(yFarthestFrom0, ah)); %overal maximum from axis
   
   [nominatorUnit, nominatorUnitLength] = extractUnit(oldunit);
   oldUnitVal = unit2val(nominatorUnit);
   if isempty(oldUnitVal),
      newunit= oldunit;
      return
   end
   trueScale = oldUnitVal .* ydatamax;  % ex. 1 mm == 0.001
   [newunit, newUnitVal] = val2unit(trueScale);
   oldunit(1:nominatorUnitLength) = [];
   newunit = [newunit, oldunit];
   
   set(ah,'ydata',get(ah,'ydata').*(oldUnitVal./newUnitVal));
   
   function [myunit, unitLength] = extractUnit(unit)
      unitLength = sum(isletter(unit(1:2)));
      myunit = unit(1:unitLength);
   end
   
   function v = unit2val(myunit)
      %unit2val   returns the associated multiplier for a unit
      %  unit2val('m') % returns 1
      %  unit2val('nm') % returns 1.0e-9
      % expects only the nominator unit eg. 'nm'
      knownunits = {'pm','nm', '\mum', 'mm','cm','m','km'};
      knownvals = 10.^[-12, -9, -6, -3, -2, 0, 3];
      whichunit = ismember(knownunits,myunit);
      if any(whichunit)
         v = knownvals(whichunit);
      else
         v = []; %not found!
      end
   end
   
   function [unit, unitval] = val2unit(v)
      %val2unit   returns the unit and multiplier for a value
      %  [a,b] = unit2val(0.0023) % a='mm', b=1.0e-3
      knownunits = {'pm','nm','\mum','mm','cm','m','km'};
      searchvals = 10.^[-inf, -9, -6, -3, -2, 0, 3]; % tweak this part if anything
      knownvals =  10.^[-12, -9, -6, -3, -2, 0, 3];
      whichunit = find((v - searchvals) >= 0, 1, 'last');
      unit = knownunits(whichunit);
      unitval = knownvals(whichunit);
   end
end