function site = db_get_site_info(stalist,datetime,dbname)


% SITE = DB_GET_SITE_INFO(STATION_LIST,DATE,DATABASE_NAME) This
% This function takes a list of stations and returns a structure containing
% relavent fields from the site table. The database must include a
% site table. The DATE field is required to resolve conflicts when a
% station configuration has changed through time. Typically the date will
% match waveform, origin or arrival data that is being extracted from the
% database. The date should be given is a string format recognized by
% antelope, or as a matlab-format numeric time.
%
%
% Example:
%    site = db_get_site_info({'AUL' 'AUH' 'AUW'},'7/1/2007','dbtmp')
% 
% 

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



% FORMAT INPUT
if ischar(stalist)
   stalist = cellstr(stalist); 
end
site.sta = reshape( stalist , numel(stalist), 1 );


% PREP DAY OF YEAR
if isreal(datetime)
   datetime = datestr(datetime,'mm/dd/yy HH:MM:SS.FFF'); 
end
jday = num2str(yearday(str2epoch(datetime)));


% GET SITE INFO
db = dbopen(dbname,'r');
db = dblookup_table(db,'site');
nlist = [];
for n = 1:length(site.sta);
	db1 = dbsubset(db,['sta==''' site.sta{n} '''']);
    db1 = dbsubset(db1,['ondate<''' jday ''' ']);
    db1 = dbsubset(db1,['offdate>''' jday ''' || offdate==NULL']);
    recnum = dbquery(db1,'dbRECORD_COUNT');
	[ site.ondate(n) , site.offdate(n) , site.lat(n) , site.lon(n) , site.elev(n) ] = dbgetv(db1,'ondate','offdate','lat','lon','elev');
end
dbclose(db);
site.ondate = reshape( site.ondate , numel(site.ondate), 1 );
site.offdate = reshape( site.offdate , numel(site.offdate), 1 );
site.lat = reshape( site.lat , numel(site.lat), 1 );
site.lon = reshape( site.lon , numel(site.lon), 1 );
site.elev = reshape( site.elev , numel(site.elev), 1 );



% plot(correlation(w));
%figure
%plot(w(1),'b')
%hold on;
%plot(w1(1),'g')
%plot(w2(1),'r')
