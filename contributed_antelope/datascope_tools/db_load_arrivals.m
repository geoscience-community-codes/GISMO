function a = db_load_arrivals(databasePath, subset_expr)
    %DB_LOAD_ARRIVALS Load arrivals from an Antelope CSS3.0 database
    %
    % arrivals = DB_LOAD_ORIGINS(dbpath) opens the arrival table belonging to
    % the database specified by dbpath. The arrival table will be joined to
    % the assoc, origin and event tables too, if these are present. If all
    % of these is present, only arrivals corresponding to preferred origins
    % will be loaded. If assoc is present, but not event or origin, only
    % arrivals referenced in the assoc table are loaded.
    %
    % The output is a structure containing the fields:
    %   * arid
    %   * sta
    %   * chan
    %   * atime (arrival date/time converted from epoch to MATLAB datenum)
    %   * iphaseQuery other tables if they exist
    %   Add in support for all fields listed above
    %   * amp
    %   * snr
    %   * seaz
    %   * iphase
    %   * delta
    %   * otime (origin date/time converted from epoch to MATLAB datenum)
    %   * orid
    %   * evid
    %
    % All these fields are vectors of numbers, or cell arrays of strings.
    % If you want more fields adding, please email Glenn    
    %
    % arrivals = DB_LOAD_ARRIVALS(dbpath, subset_expression) evaluates the
    % subset specified before reading the arrivalss. subset_expression must
    % be a valid expression accepted by dbe/dbeval.
    
    % Author: Glenn Thompson
    %
    %% To do:
    %   test

    %% Load the earthquake catalogue
    
    % Initialize output so we don't crash if return early
    a = struct('sta', [], 'chan',[], 'atime', [], 'arid',[], 'amp',[], ...
        'snr',[], 'seaz', [], 'iphase', {}, 'delta', [], 'otime', [], ...
        'orid', [], 'evid', []);

    % Check the database descriptor exists - if not abort
    if ~exist(databasePath, 'file')
        warning(sprintf('Database %s does not exist, please type in a different one',databasePath));
        return
    end
    debug.print_debug(0, sprintf('Loading data from %s',databasePath));
    ARRIVAL_TABLE_PRESENT = dbtable_present(databasePath, 'arrival');    
    if (ARRIVAL_TABLE_PRESENT) % Open the arrival table, subset if expr exists
        db = dbopen(databasePath, 'r');
        db = dblookup_table(db, 'arrival');
        numarrivals = dbquery(db,'dbRECORD_COUNT');
        debug.print_debug(1,sprintf('Got %d records from %s.arrival',numarrivals,dbpath));
        if numarrivals > 0
            ASSOC_TABLE_PRESENT = dbtable_present(dbpath, 'assoc'); 
            ORIGIN_TABLE_PRESENT = dbtable_present(dbpath, 'origin'); 
            EVENT_TABLE_PRESENT = dbtable_present(dbpath, 'event');  
            
            if (ASSOC_TABLE_PRESENT)              
                % open and join the assoc table
                db2 = dblookup_table( db , 'assoc');
                db = dbjoin(db, db2);
                
                if dbnrecs(db) > 0 & (ORIGIN_TABLE_PRESENT)
                    % open and join the origin table
                    db3=dblookup_table( db, 'origin');
                    db= dbjoin(db, db3);
                    
                    if dbnrecs(db) > 0 & (EVENT_TABLE_PRESENT)
                        % open and join the event table and subset for prefor
                        db4=dblookup_table( db, 'event');
                        db= dbjoin(db, db4);   
                        db = dbsubset('origin.orid = event.prefor');
                    end
                end
            end
            if exist('subset_expr','var')
                db = dbsubset(db, subset_expr);
            end
            
            if dbnrecs(db)>0
    
                % read (some) fields & close db
                [a.sta, a.chan, a.time, a.phase, a.arid, a.amp, a.snr, a.seaz, a.delta] = dbgetv(db, 'sta', 'chan', 'arrival.time', 'iphase', 'arid', 'amp', 'snr', 'seaz', 'delta');
                if (ORIGIN_TABLE_PRESENT)
                    [a.otime, a.orid, a.evid] = dbgetv(db, 'origin.time', 'origin.orid', 'origin.evid');
                end
 
                dbclose(db);   

                % Cell arrays don't get created if only 1 row
                if strcmp(class(a.sta),'char')
                   a.sta = {a.sta};
                   a.chan = {a.chan};
                   a.iphase = {a.iphase};
                end

                % Times are all in epoch
                a.atime = epoch2datenum(a.atime);
                a.otime = epoch2datenum(a.otime);

                % Display counts
                fprintf('\n%d arrivals\n',numel(a.atime));
            end
        end
    end

end