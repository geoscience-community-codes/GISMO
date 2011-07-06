function [yr,mn,dy]=yyyymmdd(dnum);
% Glenn Thompson, August 1999
% Usage: [y,m,d]=yyyymmdd(dnum);
% returns year, month & day strings for given Matlab datenumber

dy=datestr(dnum,7);
mn=datestr(dnum,5);
yr=datestr(dnum,10);
if dy(1)==' '
	dy(1)='0';
end
if mn(1)==' '
	mn(1)='0';
end
