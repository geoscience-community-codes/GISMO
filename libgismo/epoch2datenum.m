% TIME = EPOCH2DATENUM(EPOCH) translates Unix epoch date format into Matlab
% numeric date format. 

% Author: Michael West, Modified by Glenn Thompson. Modified further
% because epoch2str seems to crash with MATLAB2018a and Antelope 5.8
% $Date$
% $Revision$

function time = epoch2datenum(epoch)
    
    %if admin.antelope_exists()
    try
        % check ANTELOPE installation if this line segfaults
        %time = datenum(epoch2str(epoch,'%m %d %Y %H %M %S.%s'),'mm dd yyyy HH MM SS.FFF');
        time = datenum(datetime(epoch, 'convertfrom','posixtime'));
    catch
    %else % does not handle leap seconds
        time = datenum(1970,1,1,0,0,epoch);
    end
end