function dnum=epoch2datenum(e);
dnum = datenum(1970,1,1) + e/(60*60*24);
