function self = readCatalog(data_source, varargin)
%READCATALOG: Load events from various catalog data sources into a Catalog
% object.
%
%% USAGE
%
%   obj = readCatalog(data_source, 'param1', value1, 'param2', value2 ...)
%             loads a seismic event catalog into a GISMO/Catalog object.
%             data_source is a method by which the source catalog is
%             retrieved, or format in which the source catalog is stored.
%             This may be followed by named parameter-value pairs. Allowed
%             parameter-value pairs vary according to data_source.
%            
%             The output obj is a Catalog object, which itself may contain
%             a hierarchy of Event, Origin and Magnitude objects. Each of
%             these classes is styled after classes available in ObsPy. See
%             http://docs.obspy.org/packages/autogen/obspy.core.event.html
%             for details. However, it possibly mkes more sense to migrate
%	      them on CSS3.0 format.
%	      * SKELETON *

%% MODES
%
%   Data can be loaded in "fast" or "slow" RUNMODE (default is "fast").
%   In "slow" RUNMODE, a Catalog_full object is constructed consisting of Event,
%   Origin and Magnitude objects (and perhaps others as this is expanded
%   to describe a catalog in more detail).
%   In "fast" RUNMODE, a Catalog_lite object is constructed. It has no
%   underlying Event, Origin or Magnitude objects.
%   Catalog_full and Catalog_lite have a lot of common functionality as they
%   derive from the same superclass, Catalog_base.
%   To load data in "slow" RUNMODE, include the additional parameter-value
%   pair:
%       readCatalog(..., 'RUNMODE', 'slow')
%
%% LOADING FROM DATASCOPE (ANTELOPE) DATABASES
%
%   obj = readCatalog('datascope', 'dbpath', path_to_database)
%             loads events, origins and magnitudes from a Datascope
%             (Antelope) database given by the dbpath parameter-value. As a
%             minimum, the database must have an origin table.
%
%   If the database is stored in daily volumes, e.g. foo/bar_YYYY_MM_DD, 
%   rather than a single database use the 'archiveformat'
%   name/value pair, e.g.
%
%   obj = readCatalog('datascope', 'dbpath', 'foo/bar', 'archiveformat','daily');
%
%   For monthly volumes, e.g. foo/bar_YYYY_MM, set 'archiveformat' to
%   'monthly':
%
%   obj = readCatalog('datascope', 'dbpath', 'foo/bar', 'archiveformat','monthly');
%
%   obj = readCatalog('datascope', 'dbpath', path_to_database, 'subset_expression', subset_expression)
%             will subset the database given a valid datascope subset
%             expression.
%
%   If the subset_expression parameter name/value pair is omitted, a expression 
%   can also be formed from other name/value pairs. These are:
%       PARAMETER  VALUE
%       'snum'     a datenum denoting the minimum origin time
%       'enum'     a datenum denoting the maximum origin time
%       'minmag'   the minimum magnitude
%       'mindepth' the minimum depth (in km)
%       'maxdepth' the maximum depth (in km)
%       'region'   a 4-element vector: [minlon maxlon minlat maxlat]
%
%% LOADING FROM FDSN DATA SOURCES
%   obj = readCatalog('irisfetch', 'param1', value1, 'param2', value2 ...)
%             loads events, origins and magnitudes from IRIS-DMC or other
%             FSDN data sources via irisFetch.m. The allowed parameter-value 
%             pairs are those allowed by irisFetch.m. 
%
%% READING FROM A SEISAN-DERIVED DAT FILE
% 
%   obj = readCatalog('aef', 'dbpath', dbpath) 
%     will attempt to load all Seisan-derived AEF summary files in the 
%     directory specified by dbpath.
% 
%     To subset the data, use parameter name/value pairs (snum, enum, 
%     minmag, mindepth, maxdepth, region). 
%
%% READING S-FILES FROM A SEISAN YYYY/MM REA DATABASE
% 
%   obj = readCatalog('seisandb', 'dbpath', dbpath) 
%     will attempt to load all Seisan S-files in the 
%     directory specified by dbpath (which should be the parent of
%     YYYY/MM directories)
% 
%     To subset the data, use parameter name/value pairs (snum, enum, 
%     minmag, mindepth, maxdepth, region). 
%
%% EXAMPLES
%
%   (1) Import all events from the demo database
%         % get path to demo database
%         dbpath = demodb('avo');
%         % read events from database
%         obj = readCatalog('datascope', 'dbpath', dbpath);
%
%   (2) As previous example, but use a subset expression also. Here we
%       subset for origins within 15 km of Redoubt volcano:
%         obj = readCatalog('datascope', 'dbpath', dbpath, 'subset_expression', 'deg2km(distance(lat, lon, 60.4853, -152.7431))<15.0');
%
%   (3) Read all magnitude>7 events from IRIS DMC via irisFetch.m:
%         obj = readCatalog('irisfetch', 'MinimumMagnitude', 7.0);
%
%   (4) Read all events within 20 km of Redoubt volcano from IRIS DMC:
%         obj = readCatalog('irisfetch','radialcoordinates', [60.4853 -152.7431 km2deg(20)]); 
% 
%   (5) Read Alaska Earthquake Center events greater than M=4.0 in 2009
%       within rectangular region lat = 55 to 65, lon = -170 to -135 from
%       the "Total" database of all regional earthquakes in Alaska:
%         obj = readCatalog('datascope', 'dbpath', '/Seis/catalogs/aeic/Total/Total', 'snum', datenum(2009,1,1), 'enum', datenum(2010,1,1), 'minmag', 4.0, 'region', [-170.0 -135.0 55.0 65.0]);
%
%   (6) As 5, but use a subset_expression instead:
%         obj = readCatalog('datascope', 'dbpath', '/Seis/catalogs/aeic/Total/Total', 'subset_expression', 'time > "2009/1/1" & time < "2010/1/1"' & ml > 4 & lon > -170.0 & lon < -135.0 & lat > 55.0 & lat < 65.0');
%
%   (7) Read MVO data from station MBWH for all of year 2000:
%         obj = readCatalog('aef', 'dbpath', fullfile('/raid','data','seisan','mbwh_catalog'), 'snum', datenum(2000,1,1), 'enum', datenum(2000,12,31,23,59,59));
%
%   (8) Read Sfiles from MVOE_ Seisan database for January 2000 (this can be slow, especially over a network drive):
%         obj = readCatalog('seisandb', 'dbpath', fullfile('/raid','data','seisan','REA','MVOE_'), 'snum', datenum(2000,1,1), 'enum', datenum(2000,1,2) );
%
%   (9) Read from a SRU catalog in a text file:
%         obj = readCatalog('sru', '/raid/data/seisan/REA/DMNCA/DominicaCatalog.txt');
% 
%% See also CATALOG, EVENT, MAGNITUDE, IRISFETCH. CATALOG_COOKBOOK
%
% Author: Glenn Thompson (glennthompson1971@gmail.com)
% $Date: $
% $Revision: $
    switch lower(data_source)
        case {'css3.0','antelope', 'datascope'}
            % url is called dbpath within load_datascope_events
            self = load_datascope_events(varargin{:});
        case 'irisfetch'
            ev = irisFetch.Events(varargin{:});
            self = convert_irisFetch_to_Catalog(ev);
        case 'seisandb'
            self = load_seisandb(varargin{:});
        case 'aef'
            self = load_aef(varargin{:});
        case 'sru'
            self = read_SRU(varargin{:});
        otherwise
            self = NaN;
            fprintf('format %s unknown\n\n',data_source);
    end
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function self = load_datascope_events(varargin)            
    if ~admin.antelope_exists
        error('This function requires the Antelope toolbox for Matlab'); 
        return;
    end

    % Process input arguments
    p = inputParser;
    p.addParamValue('dbpath', @isstr);
    p.addParamValue('subset_expression', '', @isstr);
    p.addParamValue('archiveformat', 'single file', @isstr);
    p.addParamValue('snum', [], @isnumeric);  
    p.addParamValue('enum', [], @isnumeric);
    p.addParamValue('minmag', [], @isnumeric);
    p.addParamValue('region', [], @isnumeric);
    p.addParamValue('subclass', '*', @ischar);
    p.addParamValue('mindepth', [], @isnumeric);
    p.addParamValue('maxdepth', [], @isnumeric);
    p.addParamValue('RUNMODE', 'fast', @isstr);
    p.parse(varargin{:});
    fields = fieldnames(p.Results);
    for i=1:length(fields)
        field=fields{i};
        % val = eval(sprintf('p.Results.%s;',field));
        val = p.Results.(field);
        eval(sprintf('%s = val;',field));
    end 

    % Create a dbeval subset_expression if not already set.
    if ~exist('subset_expression', 'var') | isempty(subset_expression)
        if nargin > 2
            expr = '';
            if ~isempty(snum) & isnumeric(snum)
                expr = sprintf('%s && time >= %f',expr,datenum2epoch(snum));
            end 
            if ~isempty(enum) & isnumeric(enum)
                expr = sprintf('%s && time <= %f',expr,datenum2epoch(enum));
            end
            if ~isempty(minmag) & isnumeric(minmag)
                expr = sprintf('%s && (ml >= %f || mb >= %f || ms >= %f)',expr,minmag,minmag,minmag);
            end
            if ~isempty(region) & isnumeric(region)
                leftlon = region(1); rightlon=region(2); lowerlat=region(3); upperlat=region(4);
                expr = sprintf('%s && (lat >= %f && lat <= %f && lon >= %f && lon <= %f)',expr,lowerlat, upperlat, leftlon, rightlon);
            end
            if ~isempty(mindepth) & isnumeric(mindepth)
                expr = sprintf('%s && (depth >= %f)', expr,mindepth); 
            end
            if ~isempty(maxdepth) & isnumeric(maxdepth)
                expr = sprintf('%s && (depth <= %f)', expr,maxdepth); 
            end
            subset_expression = expr(4:end);
            clear expr
        end
    end
    
    % BUILD DBNAMELIST
    dbpathlist = {};
    
    if strcmp(archiveformat,'single file') % Just 1 entry
        dbpathlist = {dbpath};   
    else
        if isempty(snum) || isempty(enum)
            disp(sprintf('Failure: you must set values for \"snum\" and \"enum\" parameters when \"archiveformat\" is set to \"daily\" or \"monthly\"'));
            return;
        end
        if strcmp(archiveformat,'daily')
            for dnum=floor(snum):floor(enum-1/1440)
                dbpathfull = sprintf('%s_%s',dbpath,datestr(dnum, 'yyyy_mm_dd'));
                if exist(sprintf('%s.origin',dbpathfull),'file')
                    dbpathlist{end+1} = dbpathfull; % Add here
                else
                    fprintf('%s.origin not found\n',dbpath);
                end
            end
        elseif strcmp(archiveformat,'monthly')
            for yyyy=dnum2year(snum):1:dnum2year(enum)
                for mm=dnum2month(snum):1:dnum2month(enum)
                    dnum = datenum(yyyy,mm,1);
                    dbpathfull = sprintf('%s%04d_%02d',dbpath,yyyy,mm);
                    if exist(sprintf('%s.origin',dbpath),'file') 
                        dbpathlist{end+1} = dbpathfull; % Add here
                    else
                        fprintf('%s.origin not found\n',dbpath);
                    end
                end
            end
        end
    end
    
    % LOAD FROM DBNAMELIST
    % Initialize to empty
    [lat, lon, depth, dnum, time, evid, orid, nass, mag, ml, mb, ms, etype, auth] = deal([]);
    subclass = '';
    for dbpathitem = dbpathlist
        % Load vectors
        [lon0, lat0, depth0, dnum0, evid0, orid0, nass0, mag0, mb0, ml0, ms0, subclass0, auth0] = dbloadprefors(dbpathitem, subset_expression);
        if length(lon0) == length(mag0)
            % Concatentate vectors
            lon   = cat(1, lon,   lon0);
            lat   = cat(1, lat,   lat0);
            depth = cat(1, depth, depth0);
            dnum  = cat(1, dnum,  dnum0);
            evid  = cat(1, evid,  evid0);
            orid  = cat(1, orid,  orid0);
            nass  = cat(1, nass,  nass0);
            mag   = cat(1, mag,   mag0);
            mb   = cat(1, mb,   mb0);
            ml   = cat(1, ml,   ml0);
            ms   = cat(1, ms,   ms0);
            subclass  = cat(2, subclass, subclass0);
            auth = cat(1,  auth, auth0);
        end
    end
    mag(mag<-3.0)=NaN;
    if strcmp(p.Results.RUNMODE, 'slow')
        %%% SLOW MODE %%%
        % Create an Event object for each longitude in the list
        event_list = [];
        for i=1:length(lon) % Loop over each element in vector
            magnitude_obj = Netmag(mag(i));
            origin_obj = Origin(dnum(i), lon(i), lat(i), depth(i), ...
                'orid', orid(i), 'etype', subclass(i), 'netmags', [magnitude_obj] ...
                );
            event_list = [ ...
                event_list ...
                Event( ...
                    [origin_obj], ...
                    'evid', evid(i) ...
                    ) ...
                ];
        end

        % CREATE CATALOG OBJECT
        self = Catalog_full(event_list);

    elseif strcmp(p.Results.RUNMODE, 'fast')
        %%% FAST MODE %%%
        self = Catalog_lite(lat, lon, depth, dnum, mag, subclass);
    end
    st = dbstack;
    self = self.addfield('method', st(1).name);
    self = self.addfield('dbpath', dbpath);
    self = self.addfield('archiveformat', archiveformat);
    ds = datasource('antelope', dbpath);
    self = self.addfield('datasource', ds);
    
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lon, lat, depth, dnum, evid, orid, nass, mag, mb, ml, ms, etype, auth] = dbloadprefors(dbpath, subset_expression)

    numorigins = 0;
    [lat, lon, depth, dnum, time, evid, orid, nass, mag, ml, mb, ms, etype, auth] = deal([]);
    if iscell(dbpath)
        dbpath = dbpath{1};
    end
    debug.print_debug(sprintf('Loading data from %s',dbpath),3);

    ORIGIN_TABLE_PRESENT = dbtable_present(dbpath, 'origin');

    if (ORIGIN_TABLE_PRESENT)
        db = dblookup_table(dbopen(dbpath, 'r'), 'origin');
        numorigins = dbquery(db,'dbRECORD_COUNT');
        debug.print_debug(sprintf('Got %d records from %s.origin',numorigins,dbpath),1);
        if numorigins > 0
            EVENT_TABLE_PRESENT = dbtable_present(dbpath, 'event');           
            if (EVENT_TABLE_PRESENT)
                db = dbjoin(db, dblookup_table(db, 'event') );
                numorigins = dbquery(db,'dbRECORD_COUNT');
                debug.print_debug(sprintf('Got %d records after joining event with %s.origin',numorigins,dbpath),1);
                if numorigins > 0
                    db = dbsubset(db, 'orid == prefor');
                    numorigins = dbquery(db,'dbRECORD_COUNT');
                    debug.print_debug(sprintf('Got %d records after subsetting with orid==prefor',numorigins),1);
                    if numorigins > 0
                        db = dbsort(db, 'time');
                    else
                        % got no origins after subsetting for prefors - already reported
                        debug.print_debug(sprintf('%d records after subsetting with orid==prefor',numorigins),0);
                        return
                    end
                else
                    % got no origins after joining event to origin table - already reported
                    debug.print_debug(sprintf('%d records after joining event table with origin table',numorigins),0);
                    return
                end
            else
                debug.print_debug('No event table found, so will use all origins from origin table, not just prefors',0);
            end
        else
            % got no origins after opening origin table - already reported
            debug.print_debug(sprintf('origin table has %d records',numorigins),0);
            return
        end
    else
        debug.print_debug('no origin table found',0);
        return
    end

    numorigins = dbquery(db,'dbRECORD_COUNT');
    debug.print_debug(sprintf('Got %d prefors prior to subsetting',numorigins),2);

    % Do the subsetting
    if ~isempty(subset_expression)
        db = dbsubset(db, subset_expression);
        numorigins = dbquery(db,'dbRECORD_COUNT');
        debug.print_debug(sprintf('Got %d prefors after subsetting',numorigins),2);
    end

    if numorigins>0
        if EVENT_TABLE_PRESENT
            [lat, lon, depth, time, evid, orid, nass, ml, mb, ms, auth] = dbgetv(db,'lat', 'lon', 'depth', 'time', 'evid', 'orid', 'nass', 'ml', 'mb', 'ms', 'auth');
        else
            [lat, lon, depth, time, orid, nass, ml, mb, ms, auth] = dbgetv(db,'lat', 'lon', 'depth', 'time', 'orid', 'nass', 'ml', 'mb', 'ms', 'auth');  
            disp('Setting evid == orid');
            evid = orid;
        end
        etype0 = dbgetv(db,'etype');

        if isempty(etype0)
                etype = char(ones(numorigins,1)*'R');
        else
            % convert etypes
            % AVO codes are A, B, C, E, G, L, O, R, X, a, b, h, i, x and
            % '-' = the null etype in Antelope
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

            etype0=char(etype0);
            etype(etype0=='a')='t';
            etype(etype0=='A')='t';
            etype(etype0=='b')='l';
            etype(etype0=='B')='l';
            etype(etype0=='-')='u';
            etype(etype0==' ')='u';
            etype(etype0=='E')='R';
            etype(etype0=='T')='D';
            etype(etype0=='x')='u';
            etype(etype0=='X')='u';
            etype(etype0=='O')='o';
            
        end
        etype = char(etype); % sometimes etype gets converted to ASCII numbers

        % get mag
        mag = max([ml mb ms], [], 2);

        % convert time from epoch to Matlab datenumber
        dnum = epoch2datenum(time);
    end

    % close database
    dbclose(db);
end

function self = convert_irisFetch_to_Catalog(ev)
    % Create an Event object for each longitude in the list
    event_list = [];
    for i=1:length(ev) % Loop over each element in vector


       % try
            magnitude_obj = [Netmag(NaN)];
            if ~isnan(ev(i).PreferredMagnitudeValue)
                magnitude_obj = ...
                    Netmag( ...
                        ev(i).PreferredMagnitude.Value, ...
                        'magtype', ev(i).PreferredMagnitude.Type ...
                    );
            end
            origin_obj = [];
            evid = 0;
            if ev(i).PreferredTime
                origin_obj = ...
                    Origin( ...
                        datenum(ev(i).PreferredOrigin.Time), ...
                        ev(i).PreferredOrigin.Longitude, ...
                        ev(i).PreferredOrigin.Latitude, ...
                        ev(i).PreferredOrigin.Depth, ...
                        'etype', ev(i).Type, ...
                        'netmags', magnitude_obj ...
                    );
                evid = ev(i).PreferredOrigin.ContributorEventId;
            end

            if isnumeric(evid)
                event_list = ...
                    [event_list ...
                        Event( ...
                            [origin_obj], ...
                            'evid', ev(i).PreferredOrigin.ContributorEventId ... 
                        );
                    ];
            else
                 event_list = ...
                    [event_list ...
                        Event( ...
                            [origin_obj] ...
                        );
                    ];               
            end
            
        %catch ME
        %    ev(i)
        %    rethrow(ME);
        %end
    end
    
    % CREATE CATALOG OBJECT
    self = ...
        Catalog_full( ...
            event_list, ...
            'description', '' ...
        ); 
    
    st = dbstack;
    self = self.addfield('method', st(1).name);
end

% function irisFetchExists()
%     if exist('dirisFetch')~=2
%         [st,i]=dbstack();
%         error(sprintf('%s:%s:line %d: irisFetch.m not found\n',st(1).file,st(1).name,st(1).line));
%     end
% end

%% LOAD_AEF
function self = load_aef(varargin)     
    % LOAD_AEF
    %   Wrapper for loading dat files generated from Seisan S-FILES (REA) databases.
    %   DAT file name is like YYYYMM.dat
    %   DAT file format is like:
    %   
    %   YYYY MM DD HH MM SS c  MagE
    %
    %   where YYYY MM DD HH MM SS is time in UTC
    %         c is subclass
    %              r = rockfall
    %              e = lp-rockfall
    %              l = long period (lp)
    %              h = hybrid
    %              t = volcano-tectonic
    %              R = regional
    %              u = unknown
    %         MagE is equivalent magnitude, based on energy
    %         produced by the program ampengfft. These values come
    %         from magnitude database that formed part of a
    %         real-time alarm system, but these deleted were
    %         maliciously deleted in June 2003. A magnitude was
    %         computed for each event, assuming a location at sea
    %         level beneath the dome. Regardless of type. This was
    %         particularly helpful for understanding trends in
    %         cumulative energy for different types from week to
    %         week or month to month, and for real-time alarm
    %         messages about pyroclastic flow signals where an
    %         indication of event size was very important.
    %
    %  
  

    % Process input arguments
    p = inputParser;
    p.addParamValue('dbpath', '', @isstr);
    p.addParamValue('snum', 0, @isnumeric);  
    p.addParamValue('enum', now, @isnumeric);
    p.addParamValue('minmag', [], @isnumeric);
    p.addParamValue('region', [], @isnumeric);
    p.addParamValue('subclass', '*', @ischar);
    p.addParamValue('mindepth', [], @isnumeric);
    p.addParamValue('maxdepth', [], @isnumeric);
    p.addParamValue('RUNMODE', 'fast', @isstr);
    p.parse(varargin{:});
    
    fields = fieldnames(p.Results);
    for i=1:length(fields)
        field=fields{i};
        % val = eval(sprintf('p.Results.%s;',field));
        val = p.Results.(field);
        eval(sprintf('%s = val;',field));
    end
    if ~exist(dbpath, 'dir')
        fprintf('Directory %s not found. Perhaps you need to generate from S files?\n',dbpath);
        return;
    end
    
    lnum=snum;

    % loop over all years and months selected
    while (  lnum <= enum ),
        [yyyy, mm] = datevec(lnum);

        % concatenate catalogs
        obj0 = import_aef_file(dbpath,yyyy,mm,snum,enum,p.Results.RUNMODE);
        if exist('self', 'var')
            self = self + obj0;
        else
            self = obj0;
        end
        clear obj0;
        
        % ready for following month
        lnum=datenum(yyyy,mm+1,1);
    end

    self.mag(self.mag<-3)=NaN;

    if ~isempty(self.dnum)

        % cut data according to threshold mag
        if ~isempty(minmag)
            disp('Applying minimum magnitude filter')
            m = find(self.mag > minmag);
            fprintf('Accepting %d events out of %d\n',length(m),length(self.dnum));
            self.event_list = self.event_list(m);
        end    
    end
end
        

        
        
%% IMPORT_AEF_FILE       
function self = import_aef_file(dirpath, yyyy, mm, snum, enum, RUNMODE)
    self = [];
    fprintf('\nAPPEND SEISAN %4d-%02d\n',yyyy,mm)
    datfile = fullfile(dirpath,sprintf('%4d%02d.dat',yyyy,mm));
    if exist(datfile,'file') 
        disp(['loading ',datfile]);
        [yr,mn,dd,hh,mi,ss,etype0,mag0] = textread(datfile,'%d %d %d %d %d %d %s %f');
        dnum = datenum(yr,mn,dd,hh,mi,ss)';
        mag = mag0';
        etype = char(etype0)';
        l = length(dnum);      
        
        if strcmp(RUNMODE, 'slow')
            % SLOW MODE
            % Create an Event object for each dnum in the list
            event_list = [];
            for i=1:l % Loop over each element in vector
                if dnum(i)>=snum & dnum(i)<=enum
                    disp(sprintf('%s %5.2f',datestr(dnum(i)), mag(i)))
                    if mag(i) < -3.0
                        mag(i) = NaN;
                    end
                    magnitude_obj = Netmag(mag(i));
                    origin_obj = Origin(dnum(i), NaN, NaN, NaN, ...
                            'orid', str2num(sprintf('%4d%02d_%05d',yyyy,mm,i)), ...
                            'netmags', [magnitude_obj], ...
                            'etype', etype(i) ...
                        );
                    event_list = [ ...
                        event_list ...
                        Event( ...
                            [origin_obj], ...
                            'evid', str2num(sprintf('%4d%02d_%05d',yyyy,mm,i)) ...
                            ) ...
                        ];
                end
            end

            % CREATE CATALOG OBJECT
            self = Catalog_full( event_list );
        elseif strcmp(RUNMODE, 'fast')
            % FAST MODE
            self = Catalog_lite([], [], [], dnum, mag, etype); 
        end
        st = dbstack;
        self = self.addfield('method', st(1).name);
        self = self.addfield('dbpath', dirpath);
    else
        disp([datfile,' not found']);
    end

end

function self = load_seisandb(varargin)
    % LOAD_SEISANDB
    %   Wrapper for loading dat files generated from Seisan S-FILES (REA) databases.
    %   DAT file name is like YYYYMM.dat
    %   DAT file format is like:
    %   
    %   YYYY MM DD HH MM SS c  MagE
    %
    %   where YYYY MM DD HH MM SS is time in UTC
    %         c is subclass
    %              r = rockfall
    %              e = lp-rockfall
    %              l = long period (lp)
    %              h = hybrid
    %              t = volcano-tectonic
    %              R = regional
    %              u = unknown
    %         MagE is equivalent magnitude, based on energy
    %         produced by the program ampengfft. These values come
    %         from magnitude database that formed part of a
    %         real-time alarm system, but these were deleted in June 2003.
    %
    %         A magnitude was
    %         computed for each event, assuming a location at sea
    %         level beneath the dome. Regardless of type. This was
    %         particularly helpful for understanding trends in
    %         cumulative energy for different types from week to
    %         week or month to month, and for real-time alarm
    %         messages about pyroclastic flow signals where an
    %         indication of event size was very important.
    %
    %  

    % Process input arguments
    p = inputParser;
    p.addParamValue('dbpath', '', @isstr);
    p.addParamValue('snum', 0, @isnumeric);  
    p.addParamValue('enum', now, @isnumeric);
    p.addParamValue('RUNMODE', 'fast', @isstr);
    p.parse(varargin{:});
    fields = fieldnames(p.Results);
    for i=1:length(fields)
        field=fields{i};
        % val = eval(sprintf('p.Results.%s;',field));
        val = p.Results.field;
        eval(sprintf('%s = val;',field));
    end
    
    if ~exist(dbpath, 'dir')
        fprintf('Directory %s not found\n',dbpath);
        self = struct;
        return;
    end
    
    % get dir list of matching sfiles
    sfiles = list_sfiles(dbpath, snum, enum);
    
    % loop over sfiles

    for i=1:length(sfiles)
        % read 
        disp(sprintf('Processing %s',fullfile(sfiles(i).dir, sfiles(i).name)));

        thiss = read_sfile(sfiles(i).dir, sfiles(i).name, '*', '*');

        try
            s(i)=thiss;
        catch
            s(i)
            thiss
            warning('Wrong number of fields?')
        end
s(i)
        % add to catalog
        dnum(i)  = s(i).dnum;
        etype(i) = s(i).subclass;
        lat(i) = s(i).latitude;
        lon(i) = s(i).longitude;
        depth(i) = s(i).depth;
        s(i).magnitude
        % SKELETON
        mag(i) = NaN;
        try
            sfile_mags = [s(i).magnitude.value];
            if ~isempty(sfile_mags)
                disp('**************** ********************')
                mag(i) = max(sfile_mags);
            end
        end

        % also do something with parameters spdur, bbdur, amp, eng, pkf,
        % station
        % Compute a magnitude from amp & eng, but need to know where
        % stations are. I can save these as MA and ME, to distinguish from
        % Ml, Ms, Mb, Mw if those exist
%         catch
%             i
%             %s(i) = struct();
%             disp('- failed');
%             dnum(i) = NaN;
%             etype(i) = 'u';
%         end
    end

    l = length(dnum);      

    if strcmp(RUNMODE, 'slow')
        % SLOW MODE
        % Create an Event object for each dnum in the list
        event_list = [];
        for i=1:l % Loop over each element in vector
            if dnum(i)>=snum & dnum(i)<=enum
                [yyyy,mm]=datevec(dnum(i));
                disp(sprintf('%s %5.2f',datestr(dnum(i)), mag(i)))
                if mag(i) < -3.0
                    mag(i) = NaN;
                end
                magnitude_obj = Netmag(mag(i));
                origin_obj = Origin(dnum(i), lon(i), lat(i), depth(i), ...
                        'orid', str2num(sprintf('%4d%02d%05d',yyyy,mm,i)), ...
                        'etype', etype(i), ...
                        'netmags', [magnitude_obj] ...
                    );
                event_list = [ ...
                    event_list ...
                    Event( ...
                        [origin_obj], ...
                        'evid', str2num(sprintf('%4d%02d%05d',yyyy,mm,i)) ...
                        ) ...
                    ];
            end
        end

        % CREATE CATALOG OBJECT
        self = Catalog_full(event_list);
    elseif strcmp(RUNMODE, 'fast')
        % FAST MODE
        self = Catalog_lite([], [], [], dnum, mag, etype);
    end
    st = dbstack;
    self = self.addfield('method', st(1).name);
    self = self.addfield('dbpath', dbpath);
    self = self.addfield('sfile', s);
    wavdbpath = strrep(dbpath, 'REA', 'WAV');
    ds = datasource('seisan', wavdbpath);
    self = self.addfield('datasource', ds);
end

function files = list_sfiles(dbpath, snum, enum)
    % LIST_SFILES Load waveform files from a Seisan database 
    %   s = list_sfiles(dbpath, snum, enum) search a Seisan
    %   database for Sfiles matching the time range given by snum
    %   and enum.
    %
    %   Notes:
    %     Seisan Sfiles are typically stored in a Seisan
    %     Seisan database, which is a tree of 4-digit-year/2-digit-month 
    %     directories. They have a name matching DD-HHMM-SSc.SYYYYMM
    %
    %   Example:
    %       Load all data for all stations & channels between 1000 and 1100
    %       UTC on March 1st, 2001.
    %           
    %           dbpath = '/raid/data/seisan/REA/DSNC_';
    %           snum = datenum(2001,3,1,10,0,0);
    %           enum = datenum(2001,3,1,11,0,0);
    %           s = list_sfiles(dbpath, snum, enum)
    %

    files = [];
    
    % Test dbpath
    if ~exist(dbpath,'dir')
        disp(sprintf('dbpath %s not found',dbpath))
        return
    end
        
    %% Compile a list from all directories from snum to enum
    sdv = datevec(snum);
    edv = datevec(enum);
    fileindex = 0;
    for yyyy=sdv(1):edv(1)
       for mm=sdv(2):edv(2)
           seisandir = fullfile(dbpath, sprintf('%4d',yyyy), sprintf('%02d',mm) );
           newfiles = dir(fullfile(seisandir, sprintf('*%4d%02d',yyyy,mm)));
           for i=1:length(newfiles)
               dnum = sfile2dnum(newfiles(i).name);
               if dnum >= snum & dnum <= enum
                   fileindex = fileindex + 1;
                   newfiles(i).dir = seisandir;
                   files = [files; newfiles(i)];
               elseif dnum>enum
                   break;
               end
           end
       end
    end

    %% Echo the list of matching sfiles
    disp(sprintf('There are %d sfiles matching your request',numel(files)))
end


function s=read_sfile(sfiledir, sfilebase,sta,chan);
% READ_SFILE import data from a single MVO SFILE generated in SEISAN.
% USAGE: s=read_sfile(sfiledir, sfilebase,sta,chan)
% INPUT VARIABLES:
%   sfiledir = directory of the S-file
%   sfilebase = basename of the S-file
%   sta = the station to load, or can be set to '*' for all
%   chan = the channel to load, or can be set to '*' for all
%       note: only last character of chan is used for matching presently
% OUTPUT VARIABLES:
%   s = a structure containing
%       aef = a structure with vector fields        
%           amp = MAX AVERAGE AMPLITUDE OF SIGNAL
%           eng = SEISMIC ENERGY
%           ssam = percentage of energy in 11 different frequency bins
%           pkf = PEAK FREQUENCY
%           scnl = SCNLOBJECT
%       stime = EVENT TIME
%       ...and many more variables...
%
% EXAMPLE:
%   s = read_sfile('/raid/data/seisan/REA/MVOE_/2002/02', '27-2109-46L.S200202','*', '*')
%   s = read_sfile('/raid/data/seisan/AEF/MVOE_/2002/02', '2002-02-27-2311-34S.MVO___014.aef','*','*')

    % Validate    
    fullpath = fullfile(sfiledir, sfilebase);
    if ~ischar(fullpath) || ~exist(fullpath)
        warning(sprintf('catalog:readCatalog:notFound','%s not found',fullpath));
        % eval(['help ' mfilename]);
        help(mfilename);
    end

    % initialize
    s = struct();
    s.aef = struct('amp', [], 'eng', [], 'ssam', {}, 'pkf', [], 'scnl', []);
    s.subclass='_';                  
    s.bbdur=NaN; 
    s.stime = '';
    s.dnum = sfile2dnum(sfilebase);
    s.wavfiles = '';
    s.error = NaN;
    s.gap = NaN;
    s.magnitude = struct();
    s.longitude = NaN;
    s.latitude = NaN;
    s.depth = NaN;
    aef = struct();
    
    % open file 
    fid=fopen(fullpath,'r');
    patternstr = ['VOLC',' ',sta];
  
    linenum = 1;
    aeflinenum = 0;
    magnum = 0;
    while fid ~= -1,
        tline = fgetl(fid);
        %disp(sprintf('line = %d',linenum));
        %disp(tline);
        linelength=length(tline);    
        if ischar(tline) & linelength == 80 % must be an 80 character string, or close file
            
            if tline(80) == '1'
                if length(strtrim(tline(2:20)))  >= 14
                    s.year = str2num(tline(2:5));
                    s.month = str2num(tline(7:8));
                    day = str2num(tline(9:10));
                    hour = str2num(tline(12:13));
                    minute = str2num(tline(14:15));
                    second = str2num(tline(17:20));
                    if floor(second) == 60
                        minute = minute + 1;
                        second = second - 60.0;
                    end
                    s.otime = datenum(s.year, s.month, day, hour, minute, floor(second));
                end
                s.mainclass = strtrim(tline(22:23));
                lat = str2num(tline(24:30));
                lon = str2num(tline(31:38));
                depth = str2num(tline(39:43));
                if isempty(lat)
                    s.latitude = NaN;
                end
                if isempty(lon)
                    s.longitude = NaN;
                end     
                if isempty(depth)
                    s.depth = NaN;
                end                    
                s.z_indicator = strtrim(tline(44));
                s.agency = strtrim(tline(46:48));
                s.no_sta=str2num(tline(49:51));
                if isempty(s.no_sta)
                    s.no_sta=0;
                end
                s.rms=str2num(tline(52:55));
                tline(56:75)
                if ~isempty(strtrim(tline(56:59)));
                    magnum = magnum + 1;
                    s.magnitude(magnum).value = str2num(tline(56:59));
                    s.magnitude(magnum).type = tline(60);
                    s.magnitude(magnum).agency = strtrim(tline(61:63));
                end
                if ~isempty(strtrim(tline(64:67)))
                    magnum = magnum + 1;
                    s.magnitude(magnum).value = str2num(tline(64:67));
                    s.magnitude(magnum).type = tline(68);
                    s.magnitude(magnum).agency = strtrim(tline(69:71));
                end
                if ~isempty(strtrim(tline(72:75)))
                    magnum = magnum + 1;
                    s.magnitude(magnum).value = str2num(tline(72:75));
                    s.magnitude(magnum).type = tline(76);
                    s.magnitude(magnum).agency = strtrim(tline(77:79));
                end                
            end
                        
            % Process Type 2 line, Macroseismic Intensity Information
            if tline(80) == '2'
               s.maximum_intensity=str2num(tline(28:29));
            end
               
            if tline(80) == '3'   % This is SEISAN identifier for summary lines in the Sfile                
                if strfind(tline,'VOLC')                   
                    if strfind(tline,'MAIN')  % This identifies the volcanic type 
                        s.subclass=tline(12);
                    else % A TYPE 3 LINE LIKE "VOLC STA"
                        if strcmp(sta,'*') || strfind(tline,sta)
                            if strcmp(chan,'*') ||  strfind(tline(14:15),chan(end))
                                aeflinenum = aeflinenum + 1;
                                thissta = strtrim(tline(7:10));
                                thischan = strtrim(tline(12:15));
                                aef.scnl(aeflinenum) = scnlobject(thissta, thischan);
                                try
                                    %aef.amp(aeflinenum)=str2num(tline(20:27));
                                    aef.amp(aeflinenum)=str2num(tline(18:25));
                                catch
                                    tline
                                    tline(20:27)
                                    aeflinenum
                                    aef.amp
                                    error('aef.amp')
                                end
                                %aef.eng(aeflinenum)=str2num(tline(30:37));
                                aef.eng(aeflinenum)=str2num(tline(28:35));
                                for i = 1:11
                                    %startindex = (i-1)*3 + 40;
                                    startindex = (i-1)*3 + 38;
                                    ssam(i) = str2num(tline(startindex:startindex+1));
                                end
                                aef.ssam{aeflinenum} = ssam;
                                aef.pkf(aeflinenum)=str2num(tline(73:77));   % Peak frequency (Frequency of the largest peak
                            end
                        end
                    end
                elseif strcmp(tline(2:7), 'ExtMag')
                    magnum = magnum + 1;
                    s.magnitude(magnum).value = str2num(tline(9:12));
                    s.magnitude(magnum).type = tline(13);
                    s.magnitude(magnum).agency = strtrim(tline(14:16));   
                elseif strcmp(tline(1:4), 'URL')
                    s.url = strtrim(tline(6:78));
                end
                   
            end
            
            if tline(80) == '6'
                s.wavfiles = tline(2:79);
                wavfile{1} = tline(2:36);
            end
            
            % Process Type E line, Hyp error estimates
            if tline(80) == 'E'
                s.gap=str2num(tline(6:8));
                s.error.origintime=str2num(tline(15:20));
                s.error.latitude=str2num(tline(25:30));
                s.error.longitude=str2num(tline(33:38));
                s.error.depth=str2num(tline(39:43));
                s.error.covxy=str2num(tline(44:55));
                s.error.covxz=str2num(tline(56:67));
                s.error.covyz=str2num(tline(68:79));
            end
            
            % Process Type F line, Fault plane solution
            % Format has changed need to fix AAH - 2011-06-23
            if tline(80) == 'F' %and not s.focmec.has_key('dip'):
                s.focmec.strike=str2num(tline(1:10));
                s.focmec.dip=str2num(tline(11:20));
                s.focmec.rake=str2num(tline(21:30));
                %s.focmec.bad_pols=str2num(tline(61:66));
                s.focmec.agency=tline(67:69);
                s.focmec.source=tline(71:77);
                s.focmec.quality=tline(78);
            end
            
            % Process Type H line, High accuracy line
            % This replaces some origin parameters with more accurate ones
            if tline(80) == 'H'
                osec0=str2num(tline(17:22));
                yyyy0=str2num(tline(2:5));
                mm0=str2num(tline(7:8));
                dd0=str2num(tline(9:10));
                hh0=str2num(tline(12:13));
                mi0=str2num(tline(14:15));
                s.otime=datenum(yyyy0, mm0, dd0, hh0, mi0, osec0)
                s.latitude=str2num(tline(24:32));
                s.longitude=str2num(tline(34:43));
                s.depth=str2num(tline(45:52));
                s.rms=str2num(tline(54:59));   
            end
            
            if tline(80) == 'I'
                s.last_action=strtrim(tline(9:11));
                s.action_time=strtrim(tline(13:26));
                s.analyst = strtrim(tline(31:33));
                s.id = str2num(tline(61:74));
            end  
            
            if tline(2:8)=='trigger' 
                s.bbdur=str2num(tline(18:19)); % EARTHWORM TRIGGER DURATION (including pre & posttrigger times?)
                s.bbdur=str2num(tline(19:23));
            elseif tline(2:7)=='sptrig'
                s.spdur=str2num(tline(19:23));
            end

            if tline(22:24) == 'MVO' &  (tline(80) == '6') % DATE AND TIME OF THE EVENT
                s.stime=tline(2:19);
            end
        else
            fclose(fid);
            break
        end
        linenum = linenum + 1;
    end
    s.aef = aef;
end

function sfilednum=sfile2dnum(sfile)
    ddstr=sfile(1:2);
    hhstr=sfile(4:5);
    mistr=sfile(6:7);
    ssstr=sfile(9:10);
    yystr=sfile(14:17);
    mm=str2num(sfile(18:19));
    months=['Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dec'];
    mmstr=months(mm,:);
    datestring=[ddstr,'-',mmstr,'-',yystr,' ',hhstr,':',mistr,':',ssstr];
    try
        sfilednum=datenum(datestring);
    catch
        error(sprintf('Could not convert %s to a datenum for sfile=%s. Returning 0', datestring, sfile));
    end
end

function self=read_vdap(filename)
%READ_VDAP read Hypoellipse summary files and PHA pickfiles
%   based on Montserrat analog network
%   cobj = read_vdap(filename) will read the catalog file, and create a
%   Catalog object
%
%   Summary file has lines like:
%
%   PHA phase file has lines like:
%   MGHZEP 1 950814071436.76
%   MSPTIPU0 950814071437.96
%   MGATEPU0 950814071437.92                                              00011
%   MLGT PD0 950814071438.09       39.41 S 2
%   MWHTEPD1 950814071437.61       38.78 S 2                              00009
%   1-4: sta code
%   5:   E or I
%   6:   P (or blank)
%   7:   U or D
%   8:   quality 0-4
%  10-24: YYMMDDhhmmss.ii for P
%  31-35: ss.ii for S
%  37:   S (or blank)
%  39:   quality 0-4
% Glenn Thompson 2014/11/14

    %% read the headers and data
    fid = fopen(phafilename);
    tline = fgetl(fid);
    while ischar(tline)
        tline = fgetl(fid);
        stacode = tline(1:4);
        p_eori = tline(5);
        p = tline(6);
        p_uord = tline(7);
        p_qual = tline(8);
        p_datetime = tline(10:24);
        s_datetime = tline(31:35);
        s = tline(37);
        s_qual = tline(39);
    end
    fclose(fid);


end


function self=read_SRU(filename)
%READ_SRU read a catalog sent by Seismic Research Unit, University of West
%Indies
%   Based on a Dominica catalog sent to Ophelia George
%   cobj = read_SRU(filename) will read the catalog file, and create a
%   Catalog object
%
%   File has lines like:
%   #EVENT_ID	P	S	LAT.	LONG	DEP.	DATE	TIME	RMSE	MAG.
%   9703120.002	3	3	15.4170N	61.2890W	3	19970322	658.23	0.347	2.5
%
% Glenn Thompson 2014/11/14

    %% read the headers and data
    fid = fopen(filename);
    headers = textscan(fid, '%s', 10); % header is just 10 strings
    data = textscan(fid, '%f%d%d%s%s%f%s%f%f%f'); % import the columns from each tab separated row as float, integer, integer, string, ...
    fclose(fid);
    
    %% wrangle the data into variables we can use
    evid=data{1}; % event id - like 9703120.002 - but we'll probably just renumber them from 1
    nassP=data{2}; % number of associated P arrivals - like 3
    nassS=data{3}; % number of associated S arrivals - like 3
    
    % latitude like '15.4170N'
    latstr = data{4};
    for c=1:numel(latstr)
        thislatstr = latstr{c};
        hemisphere = thislatstr(end);
        lat(c) = str2num(thislatstr(1:end-1));
        if lower(hemisphere)=='s'
            lat(c) = -lat(c);
        end
    end
    
    % longitude like '61.2890W'
    lonstr = data{5};
    for c=1:numel(lonstr)
        thislonstr = lonstr{c};
        hemisphere = thislonstr(end);
        lon(c) = str2num(thislonstr(1:end-1));
        if lower(hemisphere)=='w'
            lon(c) = -lon(c);
        end
    end
    
    % depth like 3
    depth = data{6};
    
    % date like 19970322
    yyyymmdd = data{7};
    for c=1:numel(yyyymmdd)
        thisyyyymmdd = yyyymmdd{c};
        yyyy(c) = str2num(thisyyyymmdd(:,1:4));
        mo(c) = str2num(thisyyyymmdd(:,5:6));
        dd(c) = str2num(thisyyyymmdd(:,7:8));
    end
    
    % time like 658.23 for 00:06:58.23 but really HHMMSS.MS
    hhmmss = data{8};
    for c=1:numel(hhmmss)
        thishhmmss = sprintf('%09.2f',hhmmss(c));
        hh(c) = str2num(thishhmmss(:,1:2));
        mm(c) = str2num(thishhmmss(:,3:4));
        ss(c) = str2num(thishhmmss(:,5:9));
    end
    
    dnum = datenum(yyyy, mo, dd, hh, mm, ss);
    datestr(dnum)
    
    % RMS Error
    rms = data{9};
    
    % Magnitude
    mag = data{10};
    
    
    %% Create an etype (assume type 'tectonic')
    etype = repmat('t',numel(dnum));
    
    %% Create our Catalog object
    % FAST MODE
    self = Catalog_lite(lat, lon, depth, dnum, mag, etype);
    % WE COULD ADD ANOTHER METHOD HERE IN SLOW MODE TO CREATE A FULL
    % CATALOG OBJECT, MAKING USE OF FIELDS LIKE nassP, rms etc.
end