function juldaystr = datenum2julday(dnum)
[yyyy, mm, dd, hh, mi, ss] = datevec(dnum);
dnum_jan1 = datenum(yyyy, 1, 1);
dnum_diff = dnum - dnum_jan1;
julday = ceil(dnum_diff + eps); % eps turns datenum(1997,1,1) into day 1 rather than day 0
juldaystr = sprintf('%4d%03d', yyyy, julday);
