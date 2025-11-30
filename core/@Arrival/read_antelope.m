function arrivalObj = read_antelope(dbname, subset_expr)
%READ_ANTELOPE Load arrivals from CSS3.0 Antelope database

ARRIVAL_TABLE_PRESENT = antelope.dbtable_present(dbname,'arrival');
ASSOC_TABLE_PRESENT   = antelope.dbtable_present(dbname,'assoc');
ORIGIN_TABLE_PRESENT  = antelope.dbtable_present(dbname,'origin');

if ~ARRIVAL_TABLE_PRESENT
    fprintf('No arrival table in %s\n',dbname);
    return
end

db = dbopen(dbname,'r');
db = dblookup_table(db,'arrival');

if exist('subset_expr','var')
    db = dbsubset(db,subset_expr);
end

nrows = dbnrecs(db);
if nrows == 0
    fprintf('No arrivals found\n');
    dbclose(db);
    return
end

db = dbsort(db,'time');

[sta,chan,time,amp,signal2noise,iphase, arid] = ...
    dbgetv(db,'sta','chan','time','amp','snr','iphase','arid');

seaz=[]; deltim=[]; delta=[]; orid=[]; evid=[]; timeres=[]; otime=[]; depth=[];

if ASSOC_TABLE_PRESENT
    db2 = dblookup_table(db,'assoc');
    db = dbjoin(db,db2);

    [sta,chan,time,amp,signal2noise,iphase, arid, seaz, deltim, delta, orid, timeres] = ...
        dbgetv(db,'sta','chan','time','amp','snr','iphase','arid', ...
               'seaz','deltim','delta','orid','timeres');

    if ORIGIN_TABLE_PRESENT
        db3 = dblookup_table(db,'origin');
        db = dbjoin(db,db3);
        [evid,otime,depth] = dbgetv(db,'evid','time','depth');
    end
end

arrivalObj = Arrival( ...
    cellstr(sta), ...
    cellstr(chan), ...
    epoch2datenum(time), ...
    cellstr(iphase), ...
    'amp', amp, ...
    'signal2noise', signal2noise, ...
    'arid', arid, ...
    'seaz', seaz, ...
    'deltim', deltim, ...
    'delta', delta, ...
    'otime', otime, ...
    'orid', orid, ...
    'evid', evid, ...
    'timeres', timeres, ...
    'depth', depth );

dbclose(db);
end
