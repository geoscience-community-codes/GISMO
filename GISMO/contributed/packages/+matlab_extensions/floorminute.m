function dnum=floorminute(dnum)
% FLOORMINUTE round up datenum to next minute mark
% dnum=floorminute(dnum)

% AUTHOR: Glenn Thompson, University of Alaska Fairbanks
% $Date$
% $Revision$
dnum=floor(dnum*1440)/1440;

