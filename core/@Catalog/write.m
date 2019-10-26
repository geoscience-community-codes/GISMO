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
            writetable(catalogObject.table(), outpath); % similar to UW/PNSN format used in REDpy

        case 'antelope'
            writemode='';
            if nargin==4
                writemode=varargin{1}; #'overwrite' or 'append';
            else
                writemode='append';
            end
            write_antelope(catalogObject, outpath, writemode); 
        case 'seisan'
            write_seisan(catalogObject, seisandbpath);
        otherwise,
            warning('format not supported yet')
    end % end switch

end

function write_seisan(catalogObject, seisandbpath)
% for each event in the Catalog, write an Sfile, and write any waveform objects as Miniseed or SAC
    for eventidx=1:catalogObject.numberOfEvents
        origin.dnum = catalogObject.otime(eventidx);
        origin.lon = catalogObject.lon(eventidx);
        origin.lat = catalogObject.lat(eventidx);
        origin.depth = catalogObject.depth(eventidx);
        origin.etype = catalogObject.etype{eventidx};
        origin.magtype = catalogObject.magtype{eventidx};
        origin.magnitude = catalogObject.mag(eventidx);
        % now figure out how to write this origin to Seisan S-file
        sfilepath = fullfile(seisandbpath, datestr(origin.dnum,'%Y'), datestr(origin.dnum,'%m')) 
        sfilename = sprintf(datestr(origin.dnum, '%d'),'-',datestr(origin.dnum,'%H%M'), '-', datestr(origin.dnum,'%S'), 'S.L', datestr(origin.dnum('%Y%m'))
        if ~exist(sfilepath, 'dir')
            mkdir(sfilepath)
        end
        % format the S-file
    end
        
end


function write_antelope(catalogObject, dbpath, writemode)
    % write_antelope(catalogObject, dbpath, writemode)
    % where writemode = 'overwrite' or 'append' to existing tables (if they exist). If not specified, error.
    if ~admin.antelope_exists
        error('Sorry, you need ANTELOPE installed to write a Catalog object to CSS3.0 tables')
    end
    if isempty(writemode)
        help(mfilename)
        error('no value given for writemode')
    end
    dbpath = outpath;

    if ~exist('schema','var')
        schema='css3.0';
    end
    if ~exist(dbpath, 'file')
        antelope.dbcreate(dbpath, schema);
    end

    if strcmp(writemode,'overwrite')
        tableNames = {'arrival';'assoc';'netmag';'stamag';'origin';'event';'wfmeas'};
        for tablenum = 1 : numel(tableNames)
            thisTable = sprintf('%s.%s',dbpath,tableNames{tablenum});
            if exist(thisTable, 'file')
                fprintf('Overwrite mode: Removing %s\n',thisTable);
                delete(thisTable);
            else
                % for 'append' mode, nothing to do
                fprintf('Append mode: You will append to %s\n',thisTable);
            end
%            system(sprintf('touch %s',thistable));
         end
    end

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
            if strcmp(origin.etype,'')
                origin.etype = '-';
            end                        
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
                              'amp', aamp, ...
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
