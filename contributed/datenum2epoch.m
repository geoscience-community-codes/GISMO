% TIME = DATENUM2EPOCH(EPOCH) translates Matlab into
% numeric date format Unix epoch date format. 
% Does not account for leap seconds.

% Author: Glenn THompson
% $Date$
% $Revision$

function epoch = datenum2epoch(time)
    epoch = (time - datenum(1970,1,1,0,0,0))*86400;
end