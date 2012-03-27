function net = db_get_net_info(stalist,dbname)


% NET = DB_GET_NET_INFO(STATION_LIST,DATABASE_NAME) 
% This function takes a list of stations and returns a structure
% containing station and network names from the snetsta table. 
% The database must include a "snetsta" table.
%
% Example:
%    net = db_get_net_info({'AUL' 'AUH' 'AUW'},'dbtmp')
% 
% 
% Yun Wang 03/25/2012

% FORMAT INPUT
if ischar(stalist)
   stalist = cellstr(stalist); 
end
sta = reshape( stalist, numel(stalist), 1 );

% GET NET INFO FROM "SNETSTA" TABLE
nr = length(sta);
net = repmat(cell(1),nr,1);
db = dbopen(dbname,'r');
db = dblookup_table(db,'snetsta');
for n = 1:nr;
	db1 = dbsubset(db,['sta==''' sta{n} '''']);
    recnum = dbquery(db1,'dbRECORD_COUNT');
	net(n) = {dbgetv(db1,'snet')};
end
dbclose(db);
end
