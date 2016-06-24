% TIME = EPOCH2DATENUM(EPOCH) translates Unix epoch date format into Matlab
% numeric date format. 

% Author: Michael West, Modified by Glenn Thompson
% $Date$
% $Revision$

function time = epoch2datenum(epoch)
    if admin.antelope_exists()
        time = datenum(epoch2str(epoch,'%m %d %Y %H %M %S.%s'),'mm dd yyyy HH MM SS.FFF');
    else % does not handle leap seconds
        time = datenum(1970,1,1,0,0,epoch);
    end
end