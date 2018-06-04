function write(catalogObject, outformat, outpath, varargin)
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
            write(catalogObject.table(), outpath); % add a table method to Catalog after changing Catalog so it no longer uses a table internally

        case 'antelope'


            if admin.antelope_exists

                dbpath = outpath;

                % create new db
                if ~exist('schema','var')
                    schema='css3.0';
                end
                antelope.dbcreate(dbpath, schema);

                % remove the following tables if they exist and mode is
                % "overwrite"
                if nargin==4 & strcmp(varargin{1},'overwrite')
                    tableNames = {'arrival';'assoc';'netmag';'stamag';'origin';'event';'wfmeas'};
                    for tablenum = 1 : numel(tableNames)
                        thisTable = sprintf('%s.%s',dbpath,tableNames{tablenum});
                        if exist(thisTable, 'file')
                            if nargin>=4
                                if strcmp(varargin{1},'overwrite')
                                    fprintf('Overwrite mode: Removing %s\n',thisTable);
                                    delete(thisTable);
                                else
                                    % for 'append' mode, nothing to do
                                    fprintf('Append mode: You will append to %s\n',thisTable);
                                end
                            else
                                % nothing specified, so force user to
                                % choose, as we never want to mess up
                                % existing tables or delete them without
                                % user input
                                choice = input(sprintf('delete %s (y/n)',thisTable),'s');
                                if lower(choice(1)=='y')
                                    fprintf('Overwrite mode: Removing %s\n',thisTable);
                                    delete(thisTable);
                                end
                            end
                        end
                    end
                end
%                 system(sprintf('touch %s.event',dbpath));
%                 system(sprintf('touch %s.origin',dbpath));
                

                disp('Writing new rows...');

                % open db
                db = dbopen(dbpath, 'r+');
                dbe = dblookup_table(db,'event');
                dbo = dblookup_table(db,'origin');
                dbn = dblookup_table(db,'netmag');
                dbas = dblookup_table(db,'assoc');
                dbar = dblookup_table(db,'arrival');
                dbs = dblookup_table(db,'stamag');
                dbwm = dblookup_table(db,'wfmeas');
                
                % write event to event and origin tables
                if numel(catalogObject.otime)>0
                    for eventidx = 1:numel(catalogObject.otime)
                        event.evid = dbnextid(dbe,'evid');
                        origin.orid = dbnextid(dbo,'orid');
                        origin.time = datenum2epoch(catalogObject.otime(eventidx));
                        origin.lon = catalogObject.lon(eventidx);
                        origin.lat = catalogObject.lat(eventidx);
                        origin.depth = catalogObject.depth(eventidx);
                        origin.etype = catalogObject.etype{eventidx};
%                         if isnan(origin.lat)
%                             origin.lat = %%% ad dfeault

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
                        dbo.record = dbaddnull(dbo);
                        if isnan(origin.lat)
                            origin.lat = -999.0;
                        end
                        if isnan(origin.lon)
                            origin.lon = -999.0;
                        end     
                        if isnan(origin.depth)
                            origin.depth = -999.0;
                        end  
%                         if strcmp(origin.etype,'')
%                             origin.etype = '-';
%                         end                        
                        dbputv(dbo, 'lat', origin.lat, ...
                            'lon', origin.lon, ...
                            'depth', origin.depth, ...
                            'time', origin.time, ...
                            'orid', origin.orid, ...
                            'evid', event.evid, ...
                            'etype', origin.etype );

                        % Add new record to netmag table & write to
                        % it
                        if isnumeric(netmag.magnitude) & netmag.magnitude > -999
                            dbn.record = dbaddnull(dbn);
                            dbputv(dbn, 'magid', netmag.magid, ...
                                'orid', origin.orid, ...
                                'evid', event.evid, ...
                                'magtype', netmag.magtype, ...
                                'magnitude', netmag.magnitude );      
                        end
                        
                        % Add wfmeas rows for each event waveform metric
                        if numel(catalogObject.waveforms) >= eventidx
                            ew = catalogObject.waveforms{eventidx};
                            N_ew = numel(ew);
                            for ewavnum=1:N_ew
                                thisEW = ew(ewavnum);
                                waveform2wfmeas(dbwm, thisEW);
                            end
                        end
                            

                        % Add new record to arrival table & write to
                        % it
                        if numel(catalogObject.arrivals) >= eventidx
                            thisA = catalogObject.arrivals{eventidx};
                            N = numel(thisA.time);
                            
                            % check if we have 1 waveform per arrival
                            w = thisA.waveforms;
                            Nw = numel(w);
                            bool_add_waveform_metrics = (N == Nw);
                            
                            if N>0
                                for arrnum = 1:N
                                    try
                                        ctag = ChannelTag(thisA.channelinfo{arrnum});
                                    catch
                                        if arrnum==1
                                            ctag = ChannelTag(thisA.channelinfo);
                                        end
                                    end
                                    asta = ctag.station;
                                    atime = datenum2epoch(thisA.time(arrnum));    
                                    aarid = dbnextid(dbar,'arid');
                                    achan = ctag.channel;
                                    aiphase = thisA.iphase{arrnum}; 
                                    aamp = -1.0; aper = -1.0; asnr = -1;
                                    try
                                        aamp = thisA.amp(arrnum);
                                    end
                                    try
                                        asnr = thisA.signal2noise(arrnum);  
                                    end
                                    try
                                        aper = thisA.per(arrnum);
                                    end
                                    
                                    % add arrival row
                                    dbar.record = dbaddnull(dbar);
                                    dbputv(dbar, 'sta', asta, ...
                                        'time', atime, ...
                                        'arid', aarid, ...
                                        'chan', achan, ...
                                        'iphase', aiphase, ...
                                        'amp', aamp, ...);
                                        'per', aper, ...
                                        'snr', asnr);
                                    
                                    % add assoc row
                                    dbas.record = dbaddnull(dbas);
                                    dbputv(dbas, 'arid', aarid, ...
                                        'orid', origin.orid, ...
                                        'sta', asta, ...
                                        'phase', aiphase); 
                                
                                
                                    if bool_add_waveform_metrics
                                        % add wfmeas row for each waveform metric
                                        thisW = w(arrnum);
                                        waveform2wfmeas(dbwm, thisW, aarid, asta, achan);
                                    end
                                end
                            end
                        end                    
                    end
                end
                dbclose(db);
                disp('(Complete)');
            end
        otherwise,
            warning('format not supported yet')
    end % end switch
end % function


function waveform2wfmeas(dbwm, thisW, aarid, asta, achan)
    wsta = get(thisW, 'station');
    wchan = get(thisW, 'channel');
    [wsnum wenum] = gettimerange(thisW);
    wstartepoch = datenum2epoch(wsnum);
    wendepoch = datenum2epoch(wenum);
    u = get(thisW,'units');
     try 
        m = get(thisW, 'metrics'); % will error if metrics not defined
        if ~isnan(m.maxAmp)
            % add minTime maxTime minAmp maxAmp
            dbwm.record = dbaddnull(dbwm);

            dbputv(dbwm, 'sta', wsta, ...
                'chan', wchan, ...
                'meastype', 'amplitude', ...
                'time', datenum2epoch(m.minTime), ...
                'endtime', datenum2epoch(m.maxTime), ...
                'val1', m.minAmp, ...
                'val2', m.maxAmp, ...
                'units1', u, ...
                'units2', u);
            if exist('aarid', 'var')
                if strcmp(wsta, asta) & strcmp(wchan, achan)
                    dbputv(dbwm, 'arid', aarid);
                end
            end   

            % add stdev
            dbwm.record = dbaddnull(dbwm);
            dbputv(dbwm, 'sta', wsta, ...
                'chan', wchan, ...
                'meastype', 'stdev', ...
                'time', wstartepoch, ...
                'endtime', wendepoch, ...
                'val1', m.stdev, ...
                'units1', u);
            if exist('aarid', 'var')
                if strcmp(wsta, asta) & strcmp(wchan, achan)
                    dbputv(dbwm, 'arid', aarid);
                end
            end  

            % add energy
            e = m.energy;
            eu = u;
            eu(eu==' ') = ''; % remove whitespace
            if length(eu)>=4 & strcmp(eu(1:4), 'nm/s')
                eu = 'nm^2/s';
            end
            if strcmp(eu(1:2), 'Pa')
                eu = 'Pa^2.s';
            end        
            if strfind(eu, 'nm')
                if e >= 1e12
                    e = e / 1e6;
                    eu = strrep(eu, 'nm', 'um');
                end
            end
            dbwm.record = dbaddnull(dbwm);
            dbputv(dbwm, 'sta', wsta, ...
                'chan', wchan, ...
                'meastype', 'energy', ...
                'time', wstartepoch, ...
                'endtime', wendepoch, ...
                'val1', e, ...
                'units1', eu);
            if exist('aarid', 'var')
                if strcmp(wsta, asta) & strcmp(wchan, achan)
                    dbputv(dbwm, 'arid', aarid);
                end
            end          

    %         %names = fieldnames(m);
    %         names = {'stdev';'energy'};
    %         for namecount = 1:numel(names)
    %             thisname = names{namecount};
    % 
    %             % write a wfmeas row for each metric in
    %             % this waveform
    %             dbwm.record = dbaddnull(dbwm);
    %             val1 = getfield(m, thisname);
    %             if strfind(thisname, 'Time')
    %                 val1=datenum2epoch(val1);
    %             end
    % 
    %             dbputv(dbwm, 'sta', wsta, ...
    %                 'chan', wchan, ...
    %                 'meastype', thisname, ...
    %                 'time', wstartepoch, ...
    %                 'endtime', wendepoch, ...
    %                 'val1', val1 );
    %                 %'filter', filterdesc, ...                
    %                 %'tmeas', atime, ...
    %                 %'twin', atwin, ...
    %                 %'val2', , ...
    %                 %'units1', , ...
    %                 %'units2', , ...
    %             if exist('aarid', 'var')
    %                 if strcmp(wsta, asta) & strcmp(wchan, achan)
    %                     dbputv(dbwm, 'arid', aarid);
    %                 end
    %             end
    %         end
        end
    catch
        disp('No metrics for this waveform object')
    end
end
