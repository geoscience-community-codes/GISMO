% TIME = EPOCH2DATENUM(EPOCH) translates Unix epoch date format into Matlab
% numeric date format.
% Does not account for leap seconds.

% Author: Glenn THompson
% $Date$
% $Revision$

function time = epoch2datenum(epoch)
    time = datenum(1970,1,1,0,0,epoch);
end