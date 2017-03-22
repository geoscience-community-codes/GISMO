function jday = datenum2julday(time)
% JDAY = DATENUM2JULDAY(TIME) translates Matlab numeric 
% date format into Unix epoch date format. 

% Author: Glenn Thompson.
% $Date$
% $Revision$
SECS_PER_DAY = 60 * 60 * 24;
jday = zeros(size(time));
for n = 1:numel(time)
	dv = datevec(time(n));
	jday(n) = dv(1)*1000 + ceil((datenum2epoch(time(n)) - datenum2epoch(datenum(dv(1),1,1)))/SECS_PER_DAY );
end

