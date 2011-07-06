function utdnum=get_utnow()
dnumnow = now;
timediff=dnumnow-datenum(zepoch2str(datenum2epoch(dnumnow), '%D %H:%M', 'US/Alaska'));
utdnum = dnumnow + timediff;

