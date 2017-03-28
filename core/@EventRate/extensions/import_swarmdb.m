%% IMPORTSWARMDB
function obj = importswarmdb(obj, dbname, auth, snum, enum)
    % IMPORTSWARMDB
    % Load a swarm database metrics table into an EventRate object
    % eventrate = importswarmdb(erobj, dbname, auth, snum, enum);  
    %
    % INPUT:
    %	dbname		the path of the database (must have a 'metrics' table)
    %	auth		name of the grid to load swarm tracking metrics for
    %	snum,enum	start and end datenumbers (Matlab time format, see 'help datenum')
    %
    % OUTPUT:
    %	obj		an eventrate object
    %
    % Example:
    %	erobj = importswarmdb('/avort/devrun/dbswarm/swarm_metadata', 'RD_lo', datenum(2010, 7, 1), datenum(2010, 7, 14) );

    % Glenn Thompson, 20100714

    % initialize
    obj.dbroot = dbname;
    obj.snum = snum;
    obj.enum = enum;
    obj.auth = auth;

    % check that database exists
    dbtablename = sprintf('%s.metrics',dbname);
    if exist(dbtablename,'file')
        % load the data
        try
            db = dbopen(dbname, 'r');
        catch me
            fprintf('Error: Could not open %s for reading',dbname);
                return;
        end
        db = dblookup_table(db, 'metrics');
        if (dbquery(db, 'dbRECORD_COUNT')==0)
            fprintf('Error: Could not open %s for reading',dbtablename);
            return;
        end
        db = dbsubset(db, sprintf('auth ~= /.*%s.*/',auth));
        numrows = dbquery(db,'dbRECORD_COUNT');
        debug.print_debug(sprintf('Got %d rows after auth subset',numrows),2);
        sepoch = datenum2epoch(snum);
        eepoch = datenum2epoch(enum);
        db = dbsubset(db, sprintf('timewindow_starttime >= %f && timewindow_endtime <= %f',sepoch,eepoch));
        numrows = dbquery(db,'dbRECORD_COUNT');
        debug.print_debug(sprintf('Got %d rows after time subset',numrows),2);

        if numrows > 0
            % Note that metrics are only saved when mean_rate >= 1.
            % Therefore there will be lots of mean_rate==0 timewindows not in
            % database.
            [tempsepoch, tempeepoch, mean_rate, median_rate, mean_mag, cum_mag] = dbgetv(db,'timewindow_starttime', 'timewindow_endtime', 'mean_rate', 'median_rate', 'mean_ml', 'cum_ml');
            obj.binsize = (tempeepoch(1) - tempsepoch(1))/86400;
            obj.stepsize = min(tempsepoch(2:end) - tempsepoch(1:end-1))/86400;
            obj.time = snum+obj.stepsize:obj.stepsize:enum;
            obj.numbins = length(obj.time);
            obj.mean_rate = zeros(obj.numbins, 1);
            obj.counts = zeros(obj.numbins, 1);
            obj.median_rate = zeros(obj.numbins, 1);
            obj.mean_mag = zeros(obj.numbins, 1);
            obj.cum_mag = zeros(obj.numbins, 1);
            for c=1:length(tempeepoch)
                tempenum = epoch2datenum(tempeepoch(c));
                i = find(obj.time == tempenum);
                obj.mean_rate(i) = mean_rate(c);
                obj.counts(i) = mean_rate(c) * (obj.binsize * 24);
                obj.median_rate(i) = median_rate(c); 
                obj.mean_mag(i) = mean_mag(c);
                obj.cum_mag(i) = cum_mag(c);
            end
        end
        dbclose(db);

    else
        % error - table does not exist
        fprintf('Error: %s does not exist',dbtablename);
        return;
    end

    obj.total_counts = sum(obj.counts)*obj.stepsize/obj.binsize;

end