function utdnum=utnow()
% UTNOW
%    ut_datenum = utnow()
%    Return a MATLAB datenum corresponding to the current UT time/date.
%    Uses Unix date command, so should work on Linux, Solaris & MacOS.  
%
%    It is a convenient way to compute UTC regardless of whether summer
%    time applies.
%
%    Caveats: 
%	Currently only configured for 'AKDT' and 'AKST'. If your Unix
%	timezone is anything else, it wont do what you want.
%
%    See also datenum, now

%    Author: Glenn Thompson
[status, unixnowstr] = system('date +"%Y-%m-%d %H:%M:%S"');
unixnow = datenum(unixnowstr);
[status, unixnowTZ] = system('date +"%Z"'); 
unixnowTZ = unixnowTZ(1:end-1); % chomp
switch unixnowTZ
    case 'AKDT'
        utdnum = unixnow + 8/24;
    case 'AKST'
        utdnum = unixnow + 9/24;
    otherwise
        utdnum = unixnow;
end
% old code below
%dnumnow = now;
%timediff=dnumnow-datenum(zepoch2str(datenum2epoch(dnumnow), '%D %H:%M', 'US/Alaska'));
%utdnum = dnumnow + timediff;

