function dnum=floorminute(dnum,nummins)
% FLOORMINUTE round up datenum to next minute mark
% dnum=floorminute(dnum)

% AUTHOR: Glenn Thompson, University of Alaska Fairbanks
% $Date$
% $Revision$
if ~exist('nummins','var')
    nummins =1;
end
factor = 1440/nummins;
dnum=floor(dnum*factor)/factor;

