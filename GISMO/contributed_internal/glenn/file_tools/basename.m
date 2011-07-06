function [bname,dname]=basename(fullpath);
% Glenn Thompson March 2003
% This function is designed to mimic the Basename module in Perl
% [bname,dname]=basename(fullpath);
% Related functions:
%   catpath;
i1=findstr(fullpath,'\');
i2=findstr(fullpath,'/');
i = sort([i1 i2]);
lasti=length(i);
l0=i(lasti);
l1=length(fullpath);
bname=fullpath(l0+1:l1);
dname=fullpath(1:l0-1);
return;
