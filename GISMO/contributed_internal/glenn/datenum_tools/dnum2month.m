function mo=dnum2month(dnum);
% Author: Glenn Thompson 2001
% extracts month of year from a date in Matlab datenumber format
%
% Usage:
%   mo=dnum2day(dnum)
%
% INPUTS:
%   dnum       - date in Matlab datenumber format
%
% OUTPUTS:
%   mo         - month of year (as a number) 
%
% EXAMPLE:
%   mo=dnum2day(datenum(2000,3,20,17,23,12))
% mo =
% 3
d=datevec(dnum);
mo=d(2);