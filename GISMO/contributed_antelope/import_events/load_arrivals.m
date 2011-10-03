function arrival = load_arrivals(dbname, subset_expr)
% LOAD_ARRIVALS Load arrivals from a CSS3.0 database


%% Load the earthquake catalogue

fprintf(2,'Loading arrivals from %s',dbname);

% Open database
db = dbopen(dbname,'r');

% Apply subset expression
db = dblookup_table(db,'origin');
db1 = dblookup_table(db,'assoc');
db = dbjoin(db,db1);
db1 = dblookup_table(db,'arrival');
db = dbjoin(db,db1);
if exist('subset_expr','var')
    db = dbsubset(db,subset_expr);
end

% Sort by origin time and id
db = dbsort(db,'origin.time','orid');

% Get the values
[sta,chan,atime,otime,orid,arid,etype,stype,seaz,iphase] = dbgetv(db,'sta','chan','arrival.time','origin.time','orid','arid','etype','stype','seaz','iphase');
atime = epoch2datenum(atime);
otime = epoch2datenum(otime);

% We also want a list of unique orids.  Have to use DB operations for this
% (rather than unique()) so that sorting (by time) is preserved
db = dbgroup(db,{'origin.time','orid'});
unique_orids = dbgetv(db,'orid');

% Close database link
dbclose(db);

% Display counts
fprintf(2,'\n%d origins, %d arrivals\n',numel(unique_orids),numel(atime));

arrival.sta = sta;
arrival.chan = chan;
arrival.atime = atime;
arrival.otime = otime;
arrival.orid = orid;
arrival.arid = arid;
arrival.etype = etype;
arrival.stype = stype;
arrival.seaz = seaz;
arrival.iphase = iphase;
arrival.unique_orids = unique_orids;
clear sta atime otime orid arid etype stype seas unique_orids

