function origins = dbgetorigins(dbpath, subset_expression)
    %DBGETORIGINS Load preferred origins from an Antelope CSS3.0
    %database
    % origins = DBGETORIGINS(dbpath) opens the origin table belonging to
    % the database specified by dbpath. The origin table will be joined to
    % the event and netmag tables too, if these are present. Only preferred
    % origins are loaded. The output is a structure containing the fields:
    %   * lon
    %   * lat
    %   * depth
    %   * time (date/time converted from epoch to MATLAB datenum)
    %   * evid
    %   * orid
    %   * nass
    %   * mag
    %   * mb
    %   * ml
    %   * ms
    %   * etype
    %   * auth
    %   * magtype
    %
    % All these fields are vectors of numbers, apart from the last 3 which
    % are cell arrays of strings.
    %
    % origins = DBGETORIGINS(dbpath, subset_expression) evaluates the
    % subset specified before reading the origins. subset_expression must
    % be a valid expression accepted by dbe/dbeval.
    
    debug.printfunctionstack('>')
    

    % initialize
    numorigins = 0;
    origins = struct();
    [lat, lon, depth, time, evid, orid, nass, mag, ml, mb, ms] = deal([]);
    [etype, auth, magtype] = deal({});
    
    % process command line arguments
    if ~exist('dbpath','var')
        warning('No dbpath given')
        return
    end
    if ~exist('subset_expression','var')
        subset_expression = '';
        return
    end 
    
    % ensure dbpath is a string, not a cell
    if iscell(dbpath)
        dbpath = dbpath{1};
    end
    
    debug.print_debug(0, sprintf('Loading data from %s',dbpath));
    ORIGIN_TABLE_PRESENT = antelope.dbtable_present(dbpath, 'origin');
    dbpath
    if (ORIGIN_TABLE_PRESENT)
        db = dblookup_table(dbopen(dbpath, 'r'), 'origin');
        numorigins = dbquery(db,'dbRECORD_COUNT');
        debug.print_debug(1,sprintf('Got %d records from %s.origin',numorigins,dbpath));
        if numorigins > 0
            EVENT_TABLE_PRESENT = antelope.dbtable_present(dbpath, 'event'); 
            NETMAG_TABLE_PRESENT = antelope.dbtable_present(dbpath, 'netmag');  
            if (EVENT_TABLE_PRESENT)
                db = dbjoin(db, dblookup_table(db, 'event') );
                numorigins = dbquery(db,'dbRECORD_COUNT');
                debug.print_debug(1,sprintf('Got %d records after joining event with %s.origin',numorigins,dbpath));
                if numorigins > 0
                    db = dbsubset(db, 'orid == prefor');
                    numorigins = dbquery(db,'dbRECORD_COUNT');
                    debug.print_debug(1,sprintf('Got %d records after subsetting with orid==prefor',numorigins));
                    if numorigins > 0
                        db = dbsort(db, 'time');
                    else
                        % got no origins after subsetting for prefors - already reported
                        debug.print_debug(1,sprintf('%d records after subsetting with orid==prefor',numorigins));
                        return
                    end
                else
                    % got no origins after joining event to origin table - already reported
                    debug.print_debug(1,sprintf('%d records after joining event table with origin table',numorigins));
                    return
                end
            else
                debug.print_debug(0,'No event table found, so will use all origins from origin table, not just prefors');
            end
        else
            % got no origins after opening origin table - already reported
            debug.print_debug(0,sprintf('origin table has %d records',numorigins));
            return
        end
    else
        debug.print_debug(0,'no origin table found');
        return
    end

    numorigins = dbquery(db,'dbRECORD_COUNT');
    debug.print_debug(2,sprintf('Got %d prefors prior to subsetting',numorigins));

    % Do the subsetting
    if ~isempty(subset_expression)
        db = dbsubset(db, subset_expression);
        numorigins = dbquery(db,'dbRECORD_COUNT');
        debug.print_debug(2,sprintf('Got %d prefors after subsetting',numorigins));
    end

    if numorigins>0
        if EVENT_TABLE_PRESENT
            [lat, lon, depth, time, evid, orid, nass, ml, mb, ms, auth] = dbgetv(db,'lat', 'lon', 'depth', 'time', 'evid', 'orid', 'nass', 'ml', 'mb', 'ms', 'auth');
        else
            [lat, lon, depth, time, orid, nass, ml, mb, ms, auth] = dbgetv(db,'lat', 'lon', 'depth', 'time', 'orid', 'nass', 'ml', 'mb', 'ms', 'auth');  
            disp('Setting evid == orid');
            evid = orid;
        end
        etype = dbgetv(db,'etype');

        % convert etypes?
        % AVO Classification Codes
        % 'a' = Volcano-Tectonic (VT)
        % 'b' = Low-Frequency (LF)
        % 'h' = Hybrid
        % 'E' = Regional-Tectonic
        % 'T' = Teleseismic
        % 'i' = Shore-Ice
        % 'C' = Calibrations
        % 'o' = Other non-seismic
        % 'x' = Cause unknown
        % But AVO catalog also contains A, B, G, L, O, R, X
        % Assuming A, B, O and X are same as a, b, o and x, that still
        % leaves G, L and R

        % get largest mag & magtype for this mag
        [mag,magind] = max([ml mb ms], [], 2);
        magtypes = {'ml';'mb';'ms'};
        magtype = magtypes(magind);
        
        if NETMAG_TABLE_PRESENT
            % loop over each origin and find largest mag for each orid in
            % netmag
            dbn = dblookup_table(dbopen(dbpath, 'r'), 'netmag');
            numrecs = dbquery(dbn,'dbRECORD_COUNT');
            if numrecs > 0
                [nevid, norid, nmagtype, nmag] = dbgetv(dbn, 'evid', 'orid', 'magtype', 'magnitude');
            end
            for oi = 1:numel(orid)
                oin = find(norid == orid(oi));
                [mmax, indmax] = max(nmag(oin));
                if mmax > mag(oi)
                    mag(oi) = mmax;
                    magtype{oi} = nmagtype(oin(indmax));
                end
            end
        end
            
        % convert time from epoch to Matlab datenumber
        time = epoch2datenum(time);
    end

    % close database
    dbclose(db);

    origins.lat = lat;
    origins.lon = lon;
    origins.depth = depth;
    origins.time = time;
    origins.evid = evid;
    origins.orid = orid;
    origins.nass = nass;
    origins.ml = ml;
    origins.mb = mb;
    origins.ms = ms;
    origins.auth = auth;
    origins.mag = mag;
    origins.magtype = magtype;
    origins.etype = etype;

    debug.printfunctionstack('<')
end