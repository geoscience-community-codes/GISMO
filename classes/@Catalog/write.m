function write(catalogObject, outformat, outpath, schema)
    %CATALOG.WRITE Write an Catalog object to disk
    %
    % catalogObject.write('antelope', 'mydb', 'css3.0') writes the
    % catalogObject to a CSS3.0 database called 'mydb' using
    % Antelope. Requires Antelope and Antelope Toolbox. Support for
    % aefsam0.1 schema will be added later.
    % 
    % Support for other output formats, e.g. Seisan, will be added
    % later.

    % Glenn Thompson, 4 February 2015

    switch outformat
case {'text';'csv';'xls'} % help table.write for more info
    write(catalogObject.table, outpath);

        case 'antelope'


            if admin.antelope_exists

                dbpath = outpath;

                % create new db
                if ~exist('schema','var')
                    schema='css3.0';
                end
                antelope.dbcreate(dbpath, schema);

                system(sprintf('touch %s.event',dbpath));
                system(sprintf('touch %s.origin',dbpath));

                % open db
                db = dbopen(dbpath, 'r+');
                dbe = dblookup_table(db,'event');
                dbo = dblookup_table(db,'origin');
                dbn = dblookup_table(db,'netmag');

                % write event to event and origin tables
                if numel(catalogObject.datenum)>0
                    for eventidx = 1:numel(catalogObject.datenum)
                        event.evid = dbnextid(dbe,'evid');
                        origin.orid = dbnextid(dbo,'orid');
                        origin.time = datenum2epoch(catalogObject.datenum(eventidx));
                        origin.lon = catalogObject.lon(eventidx);
                        origin.lat = catalogObject.lat(eventidx);
                        origin.depth = catalogObject.depth(eventidx);
                        origin.etype = catalogObject.etype{eventidx};

                        % Antelope etype can only be two characters
                        % Antelope uses 'eq' where IRIS use
                        % 'earthquake'
                        if strcmp(origin.etype,'earthquake')
                            origin.etype = 'eq';
                        else
                            if length(origin.etype)>2
                                origin.etype=origin.etype(1:2);
                            end
                        end

                        netmag.magid = dbnextid(dbn,'magid');
                        netmag.magtype = catalogObject.magtype{eventidx};
                        netmag.magnitude = catalogObject.mag(eventidx);

                        % Add new record to event table & write to
                        % it
                        dbe.record = dbaddnull(dbe);
                        dbputv(dbe, 'evid', event.evid, ...
                            'prefor', origin.orid);

                        % Add new record to origin table & write to
                        % it
                        dbo.record = dbaddnull(dbo);
                        dbputv(dbo, 'lat', origin.lat, ...
                            'lon', origin.lon, ...
                            'depth', origin.depth, ...
                            'time', origin.time, ...
                            'orid', origin.orid, ...
                            'evid', event.evid, ...
                            'etype', origin.etype );

                        % Add new record to netmag table & write to
                        % it
                        dbn.record = dbaddnull(dbn);
                        dbputv(dbn, 'magid', netmag.magid, ...
                            'orid', origin.orid, ...
                            'evid', event.evid, ...
                            'magtype', netmag.magtype, ...
                            'magnitude', netmag.magnitude );                               

                    end
                end
                dbclose(db);
            end
        otherwise,
            warning('format not supported yet')
    end % end switch
end % function