function eseconds=epoch2datenum(dnum);

% epoch is seconds since 1/1/1970 00:00
% datenum is days since 1/1/0000 00:00

% now add the days between 1/1/1970 and 1/1/0000
daysdiff = datenum(1970,1,1);

edays = dnum - daysdiff;

eseconds = edays * 60 * 60 * 24;


return;
