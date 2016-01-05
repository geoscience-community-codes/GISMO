function [unitName, secondMultiplier] = parse_xunit(unitName)
   % PARSE_XUNIT returns a labelname and a multiplier for an incoming xunit
   % value.  This routine was removed to centralize this function
   % [unitName, secondMultiplier] = parse_xunit(unitName)
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
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