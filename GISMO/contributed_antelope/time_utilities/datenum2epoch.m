% EPOCH = DATENUM2EPOCH(TIME) translates Matlab numeric 
% date format into Unix epoch date format. Requires the 
% Antelope tool box.
%

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks

function epoch = datenum2epoch(time)


for n = 1:numel(time)
    epoch(n) = str2epoch(datestr(time(n),'mm/dd/yyyy HH:MM:SS.FFF'));
end

epoch = reshape(epoch,size(time));
