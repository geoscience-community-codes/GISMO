function dom=dnum2day(dnum);
% Author: Glenn Thompson 2001
% extracts day of month from a date in Matlab datenumber format
%
% Usage:
%   dom=dnum2day(dnum)
%
% INPUTS:
%   dnum        - date in Matlab datenumber format
%   dom         - 
%
% OUTPUTS:
%   dom         - day of month (as a number) 
%
% EXAMPLE:
%   dom=dnum2day(datenum(2000,3,20))
% dom =
% 20

d=datevec(dnum);
dom=d(3);