function rmgismo()

% RMGISMO(SOURCE) removes all existing paths containing the phrase
% 'GISMO'.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks

   
% REMOVE EXISTING GISMO PATHS
pathList = path;
n = 1;
while true
    t = strtok(pathList(n:end), pathsep);
    OnePath = sprintf('%s', t);

    if strfind(OnePath,'GISMO');
        %disp(['removing: ' OnePath])
        rmpath(OnePath);
    end;
    n = n + length(t) + 1;
    if isempty(strfind(pathList(n:end),':'))
        break
    end;
end
