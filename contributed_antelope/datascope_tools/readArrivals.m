function a = readArrivals(databasePath, expr)
    % readArrivals  Load an arrival table
    %   arrivals = readArrivals(databasePath, expr) loads an arrival table from
    %   the database indicated by databasePath, subsetted with expr. 
    %
    %   Inputs:
    %       databasePath - the path to the database descriptor
    %       expr - an optional expression with which to subset the arrival table
    %   Output:
    %       arrivals - a structure containing the fields sta, time,
    %       arid, chan, amp, snr. Each of these is a vector of length equal
    %       to the number of records
    %
    %   Author: Glenn Thompson 2014/10/16
    
    % Initialize output so we don't crash if return early
    a = struct('sta', [], 'chan',[], 'time', [], 'arid',[], 'amp',[],'snr',[], 'seaz', [], 'delta', [], 'otime', [], 'orid', [], 'evid', [], 'depth', []);

    % Check the database descriptor exists - if not abort
    if ~exist(databasePath, 'file')
        warning(sprintf('Database %s does not exist, please type in a different one',databasePath));
        return
    end

    % Open the arrival table, subset if expr exists
    db = dbopen(databasePath, 'r');
    db = dblookup_table(db, 'arrival');
    if exist('expr','var')
        db = dbsubset(db, expr);
    end
    
    % open and join the assoc table
    db2 = dblookup_table( db , 'assoc');
    db = dbjoin(db, db2);

    % open and join the origin table
    db3=dblookup_table( db, 'origin');
    db= dbjoin(db, db3);

    % read (some) fields, then close the database
    % set names to fields you will be using
    [a.sta, a.chan, a.time, a.phase, a.arid, a.amp, a.snr, a.seaz, a.delta, a.otime, a.orid, a.evid, a.depth] = dbgetv(db, 'sta', 'chan', 'arrival.time', 'iphase', 'arid', 'amp', 'snr', 'seaz', 'delta', 'origin.time', 'origin.orid', 'origin.evid', 'origin.depth');
    dbclose(db);
    
end
