% TIME = EPOCH2DATENUM(EPOCH) translates Unix epoch date format into Matlab
% numeric date format. Requires the Antelope tool box.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

function time = epoch2datenum(epoch)

% 
% if strcmp(computer,'GLNXA64')
%     error('This function requires the Antelope toolbox which currently functions only with the 32 bit Matlab libraries. Run as >> linux32 matlab'); 
% end


time = datenum(epoch2str(epoch,'%m %d %Y %H %M %S.%s'),'mm dd yyyy HH MM SS.FFF');
