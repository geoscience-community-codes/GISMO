function dnum = julday2datenum(yyyy,jday)
% DNUM = JULDAY2DATENUM2JULDAY(YYYY, JDAY) translates a Julian day to datenum 

% Author: Glenn Thompson.
% $Date$
% $Revision$
SECS_PER_DAY = 60 * 60 * 24;
for n = 1:numel(jday)
    dnum(n) = datenum(yyyy(n),1,jday(n));
end

