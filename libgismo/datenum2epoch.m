% EPOCH = DATENUM2EPOCH(TIME) translates Matlab numeric 
% date format into Unix epoch date format. 

% Author: Michael West. Modified Glenn Thompson.
% $Date$
% $Revision$

function epoch = datenum2epoch(time)


epoch = zeros(size(time));

if admin.antelope_exists()
    for n = 1:numel(time)
        epoch(n) = str2epoch(datestr(time(n),'mm/dd/yyyy HH:MM:SS.FFF'));
    end
else
    % Does not account for leap seconds.
    for n = 1:numel(time)
        epoch(n) = (time - datenum(1970,1,1,0,0,0))*86400;
    end
end