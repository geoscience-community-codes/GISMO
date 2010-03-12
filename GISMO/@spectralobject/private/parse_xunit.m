function [unitName, secondMultiplier] = parse_xunit(unitName)
% PARSE_XUNIT returns a labelname and a multiplier for an incoming xunit
% value.  This routine was removed to centralize this function
% [unitName, secondMultiplier] = parse_xunit(unitName)

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: 2010-02-11 16:11:49 -0900 (Thu, 11 Feb 2010) $
% $Revision: 193 $

mins = 60;
hrs = 3600;
days = 3600*24;


switch lower(unitName)
  case {'m','minutes'}
    unitName = 'Minutes';
    secondMultiplier = mins;
  case {'h','hours'}
    unitName = 'Hours';
    secondMultiplier = hrs;
  case {'d','days'}
    unitName = 'Days';
    secondMultiplier = days;
  case {'doy','day_of_year'}
    unitName = 'Day of Year';
    secondMultiplier = days;
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