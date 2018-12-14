% EPOCH = DATENUM2EPOCH(TIME) translates Matlab numeric 
% date format into Unix epoch date format. 

% Author: Michael West. Modified Glenn Thompson to use posixtime
% because Antelope str2epoch has been causing MATLAB2018a to segfault
% with Antelope 5.8
% $Date$
% $Revision$

function epoch = datenum2epoch(time)


epoch = zeros(size(time));
%if admin.antelope_exists()
try
    for n = 1:numel(time)
        %epoch(n) = str2epoch(datestr(time(n),'mm/dd/yyyy HH:MM:SS.FFF'));
        epoch(n) = posixtime(datetime(datestr(time(n))));
    end
catch
%else
    % Does not account for leap seconds.
    for n = 1:numel(time)
        epoch(n) = (time(n) - datenum(1970,1,1,0,0,0))*86400;
    end
end