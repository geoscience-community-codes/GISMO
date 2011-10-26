function remove

% REMOVE removes all existing paths containing the phrase
% 'GISMO'.
%
% See also admin.which admin.getpath admin.refresh



% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: 2010-02-04 11:51:43 -0900 (Thu, 04 Feb 2010) $
% $Revision: 178 $

   
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
