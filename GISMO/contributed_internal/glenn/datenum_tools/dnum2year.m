function yr=dnum2year(dnum);
% Author: Glenn Thompson 2001
% extracts year from a date in Matlab datenumber format
%
% Usage:
%   yr=dnum2day(dnum)
%
% INPUTS:
%   dnum       - date in Matlab datenumber format
%
% OUTPUTS:
%   yr         - hour of day (as a number) 
%
% EXAMPLE:
%   yr=dnum2day(datenum(2000,3,20,17,23,12))
% yr =
% 2000
d=datevec(dnum);
yr=d(1);