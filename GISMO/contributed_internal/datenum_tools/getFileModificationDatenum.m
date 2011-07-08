function dnum=getFileModificationDatenum(pathtofile)

d=dir(pathtofile);
dnum = datenum(d(1).date);
