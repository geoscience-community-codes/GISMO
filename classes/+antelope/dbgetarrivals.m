function a = dbgetarrivals(databasePath, subset_expr)
    %DBGETARRIVALS Load arrivals from an Antelope CSS3.0 database
    %
    % arrivals = DBGETORIGINS(dbpath) opens the arrival table belonging to
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
    %   * time (arrival date/time converted from epoch to MATLAB datenum)
    %   * iphase
    %   * amp
    %   * snr
    %   * seaz
    %   * deltim
    %   * iphase
    %   * delta
    %   * otime (origin date/time converted from epoch to MATLAB datenum)
    %   * orid
    %   * evid
    %   * timeres
    %   * traveltime (= time - otime)
    %
    % All these fields are vectors of numbers, or cell arrays of strings.
    % If you want more fields adding, please email Glenn    
    %
    % arrivals = DBGETARRIVALS(dbpath, subset_expression) evaluates the
    % subset specified before reading the arrivals. subset_expression must
    % be a valid expression accepted by dbe/dbeval.
    
    % Author: Glenn Thompson
    %
    %% To do:
    %   test

    %% Load the earthquake catalogue
    
    % Initialize output so we don't crash if return early
    [asta, achan, aiphase] = deal({});
    [atime, aamp, asnr, aseaz, adeltime, adelta, aotime, atimeres, atraveltime] = deal([]);
    [aarid, aorid, aevid] = deal([]);

    % Check the database descriptor exists - if not abort
    if ~exist(databasePath, 'file')
        warning(sprintf('Database %s does not exist, please type in a different one',databasePath));
        a = struct('sta', [], 'chan',[], 'time', [], 'arid',[], 'amp',[], ...
            'snr',[], 'seaz', [], 'deltim', [], 'iphase', {}, 'delta', [], 'otime', [], ...
            'orid', [], 'evid', [], 'timeres', [], 'traveltime', []);
        return
    end
    debug.print_debug(0, sprintf('Loading data from %s',databasePath));
    ARRIVAL_TABLE_PRESENT = antelope.dbtable_present(databasePath, 'arrival');    
    if (ARRIVAL_TABLE_PRESENT) % Open the arrival table, subset if expr exists
        db = dbopen(databasePath, 'r');
        db = dblookup_table(db, 'arrival');
        numarrivals = dbquery(db,'dbRECORD_COUNT');
        debug.print_debug(1,sprintf('Got %d records from %s.arrival',numarrivals,databasePath));
        if numarrivals > 0
            ASSOC_TABLE_PRESENT = antelope.dbtable_present(databasePath, 'assoc'); 
            ORIGIN_TABLE_PRESENT = antelope.dbtable_present(databasePath, 'origin'); 
            EVENT_TABLE_PRESENT = antelope.dbtable_present(databasePath, 'event');  
            
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
    
%                 % read (some) fields & close db
%                 size(dbgetv(db,'sta'))
%                 size(dbgetv(db,'chan'))
%                 size(dbgetv(db,'arrival.time'))
%                 size(dbgetv(db,'iphase'))
%                 size(dbgetv(db,'arid'))
%                 size(dbgetv(db,'amp'))
%                 size(dbgetv(db,'snr'))
%                size(dbgetv(db,'deltim'))
                [asta, achan, atime, aiphase, aarid, aamp, asnr, adeltim] = dbgetv(db, 'sta', 'chan', 'arrival.time', 'iphase', 'arid', 'amp', 'snr', 'deltim');
                a.sta = asta;
                if (ASSOC_TABLE_PRESENT)
                    [adelta, aseaz, aesaz, atimeres] = dbgetv(db, 'assoc.delta', 'assoc.seaz', 'assoc.esaz', 'assoc.timeres');
                end
                if (ORIGIN_TABLE_PRESENT)
                    [aotime, aorid, aevid] = dbgetv(db, 'origin.time', 'origin.orid', 'origin.evid');
                    atraveltime = atime - aotime;
                end
 
                dbclose(db);   

                % Cell arrays don't get created if only 1 row
                asta = cellstr(asta);
                achan = cellstr(achan);
                aiphase = cellstr(aiphase);

                % Times are all in epoch
                 atime = epoch2datenum(atime);
                 aotime = epoch2datenum(aotime);
                
            end
        end
    end
    a.sta = asta;
    a.chan = achan;
    a.time = atime;
    a.arid = aarid;
    a.amp = aamp;
    a.snr = asnr;
    a.seaz = aseaz;
    a.deltim = adeltim;
    a.iphase = aiphase;
    a.delta = adelta;
    a.otime = aotime;
    a.orid = aorid;
    a.evid = aevid;
    a.timeres = atimeres;
    a.traveltime = atraveltime;

end