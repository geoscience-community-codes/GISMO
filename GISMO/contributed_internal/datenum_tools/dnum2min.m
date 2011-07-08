function mi=dnum2min(dnum);
% Author: Glenn Thompson 2001
% extracts minute of hour from a date in Matlab datenumber format
%
% Usage:
%   mi=dnum2day(dnum)
%
% INPUTS:
%   dnum       - date in Matlab datenumber format
%
% OUTPUTS:
%   mi         - minute of hour (as a number) 
%
% EXAMPLE:
%   mi=dnum2day(datenum(2000,3,20,17,23,12))
% mi =
% 23
d=datevec(dnum);
mi=d(5);