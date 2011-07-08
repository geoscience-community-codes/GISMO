function hr=dnum2hour(dnum);
% Author: Glenn Thompson 2001
% extracts hour of day from a date in Matlab datenumber format
%
% Usage:
%   hr=dnum2day(dnum)
%
% INPUTS:
%   dnum       - date in Matlab datenumber format
%
% OUTPUTS:
%   hr         - hour of day (as a number) 
%
% EXAMPLE:
%   hr=dnum2day(datenum(2000,3,20,17,23,12))
% hr =
% 17
d=datevec(dnum);
hr=d(4);