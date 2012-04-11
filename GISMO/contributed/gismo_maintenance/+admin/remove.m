function remove

%REMOVE remove all paths to GISMO
% REMOVE Brute force function that removes any path in the path list
% that contains the string 'GISMO'.
%
% See also admin.which admin.getpath admin.refresh



% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

   
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
