function sitechan = db_get_sitechan_info(stalist,chanlist,datetime,dbname)


% SITE = DB_GET_SITECHAN_INFO(STATION_LIST,CHANNEL_LIST,DATE,DATABASE_NAME)
% This function takes a list of stations and channels and populates the
% location fields from the database given. The database must include a
% sitechan table. STATION_LIST and CHANNEL_LIST can be vectors of cells, or
% matrices of characters where each line holds one station of channel name.
% If either the station list or the channel list is a scalar while the
% other is a vector, it is expanded to the size of the other. The DATE
% field is required to resolve conflicts when a station configuration has
% changed through time. Typically the date will match waveform, origin or
% arrival data that is being extracted from the database. The date should
% be given is a string format recognized by antelope, or as a matlab-format
% numeric time.
%
% Example:
%    sitechan = db_get_sitechan_info({'AUL' 'AUL' 'AUL'},{'BHZ' 'BHN' 'BHE'},'7/1/2007','dbtmp')
% Same as:
%    sitechan = db_get_sitechan_info('AUL',{'BHZ' 'BHN' 'BHE'},733224,'dbtmp')
%
%

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$
% TODO: Current version does not output ctype and descrip fields



% FORMAT INPUT AS CELLS
if ischar(stalist)
   stalist = cellstr(stalist); 
end
if ischar(chanlist)
   chanlist = cellstr(chanlist); 
end


% FORMAT INPUT INTO COLUMNS
stalist =  reshape( stalist , numel(stalist), 1 );
chanlist = reshape( chanlist , numel(chanlist), 1 );
if numel(stalist)==1 & numel(chanlist)>1
    stalist = repmat(stalist,numel(chanlist),1);
end
if numel(chanlist)==1 & numel(stalist)>1
    chanlist = repmat(chanlist,numel(stalist),1);
end
sitechan.sta =  stalist;
sitechan.chan = chanlist;


% PREP DAY OF YEAR
if isreal(datetime)
   datetime = datestr(datetime,'mm/dd/yy HH:MM:SS.FFF'); 
end
jday = num2str(yearday(str2epoch(datetime)));


% GET SITE INFO
db = dbopen(dbname,'r');
db = dblookup_table(db,'sitechan');
nlist = [];
for n = 1:length(sitechan.sta);
	db1 = dbsubset(db,['sta==''' sitechan.sta{n} '''']);
    db1 = dbsubset(db1,['chan==''' sitechan.chan{n} '''']);
    db1 = dbsubset(db1,['ondate<''' jday ''' ']);
    db1 = dbsubset(db1,['offdate>''' jday ''' || offdate==NULL']);
    recnum = dbquery(db1,'dbRECORD_COUNT');
    % can't load descrip field. Cell structure causes problems I don't want
    % to spend time on. Not sure how ctype field is handled.
	%[ sitechan.ondate(n) , sitechan.offdate(n) , sitechan.ctype(n) , sitechan.hang(n) , sitechan.vang(n) , sitechan.descrip(n)] = dbgetv(db1,'ondate','offdate','ctype','hang','vang','descrip');
    [ sitechan.ondate(n) , sitechan.offdate(n) , sitechan.hang(n) , sitechan.vang(n)] = dbgetv(db1,'ondate','offdate','hang','vang');
end
dbclose(db);
sitechan.ondate = reshape( sitechan.ondate , numel(sitechan.ondate), 1 );
sitechan.offdate = reshape( sitechan.offdate , numel(sitechan.offdate), 1 );
%sitechan.ctype = reshape( sitechan.ctype , numel(sitechan.ctype), 1 );
sitechan.hang = reshape( sitechan.hang , numel(sitechan.hang), 1 );
sitechan.vang = reshape( sitechan.vang , numel(sitechan.vang), 1 );
%sitechan.descrip = reshape( sitechan.descrip , numel(sitechan.descrip), 1 );


