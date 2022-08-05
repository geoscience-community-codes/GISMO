function arrivalObj = antelope(dbname, subset_expr)
% LOAD_ARRIVALS Load arrivals from a CSS3.0 database
% Modifed by Glenn Thompson 2017-11-28 to include some fields from assoc table
% if present, necessary to support hankelq code
ARRIVAL_TABLE_PRESENT = antelope.dbtable_present(dbname, 'arrival');
ASSOC_TABLE_PRESENT = antelope.dbtable_present(dbname, 'assoc'); 
ORIGIN_TABLE_PRESENT = antelope.dbtable_present(dbname, 'origin'); 
EVENT_TABLE_PRESENT = antelope.dbtable_present(dbname, 'event'); 
    if ~ARRIVAL_TABLE_PRESENT
        fprintf('No arrival table belonging to %s\n',dbname);
        return
    end

    fprintf('Loading arrivals from %s\n',dbname);

    % Open database
    db = dbopen(dbname,'r');
    disp('- database opened');

    % Apply subset expression
    db = dblookup_table(db,'arrival');
    disp('- arrival table opened');
    if exist('subset_expr','var')
        db = dbsubset(db,subset_expr);
        disp('- subsetted database')
    end

    nrows = dbnrecs(db);
    if nrows > 0

        % Sort by arrival time
        db = dbsort(db,'time');
        disp('- sorted arrival table')
        
        seaz =[]; deltim=[]; delta=[]; orid=[]; evid=[]; timeres=[]; otime=[]; depth=[];
        fprintf('- reading %d rows\n',nrows);
        [sta,chan,time,amp,signal2noise,iphase, arid] = dbgetv(db,'sta','chan','time','amp','snr','iphase','arid');
        
        % Join with assoc table if present
        if ASSOC_TABLE_PRESENT
            db2 = dblookup_table( db , 'assoc');
            db = dbjoin(db, db2);

            % Get the values
            [sta,chan,time,amp,signal2noise,iphase, arid, seaz, deltim, delta, orid, timeres] = ...
                dbgetv(db,'sta','chan','time','amp','snr','iphase','arid', ...
                'seaz', 'deltim', 'delta', 'orid', 'timeres');
            
            % Join with origin table if present
            if ORIGIN_TABLE_PRESENT
                db3 = dblookup_table( db , 'origin');
                db = dbjoin(db, db3);
                if EVENT_TABLE_PRESENT
                    db4 = dblookup_table( db , 'event');
                    db = dbjoin(db, db4)
                    % force subset on prefor
                    db = dbsubset(db,'origin.orid==event.prefor');
                end
                [evid,otime,depth] = dbgetv(db,'evid','origin.time','depth');
            end
        end
        
        % Create arrival object
        disp('- creating arrival object')
        arrivalObj = Arrival(cellstr(sta), cellstr(chan), epoch2datenum(time), cellstr(iphase), ...
            'amp', amp, 'signal2noise', signal2noise, 'arid', arid, 'seaz', seaz, ...
            'deltim', deltim, 'delta', delta, 'otime', otime, 'orid', orid, ...
            'evid', evid, 'timeres', timeres, 'depth', depth);

        % Close database link
        dbclose(db);
        disp('- database closed')


        disp('- complete!')
    else
        fprintf('No arrivals found matching request\n');
    end

end
