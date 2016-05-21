function dnum=ceilminute(dnum, nummins)
% CEILMINUTE round up datenum to next minute mark
% dnum=ceilminute(dnum)

% AUTHOR: Glenn Thompson, University of Alaska Fairbanks
% $Date$
% $Revision$
if ~exist('nummins','var')
    nummins =1;
end
factor = 1440/nummins;
dnum=ceil(dnum*factor)/factor;


