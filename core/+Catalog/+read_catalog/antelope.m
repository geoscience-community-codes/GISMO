function self = antelope(varargin)   
% READ_CATALOG.ANTELOPE load events from a CSS3.0 database using Antelope.
% Requires Antelope and the Antelope toolbox from BRTT.

    debug.printfunctionstack('>')
    self = 0;
%     if ~admin.antelope_exists
%         warning('This function requires the Antelope toolbox for Matlab'); 
%         self = Catalog([], [], [], [], [], {}, {});
%         return;
%     end

    % Process input arguments
    p = inputParser;
    p.addParamValue('dbpath', @isstr);
    p.addParamValue('startTime', []);  
    p.addParamValue('endTime', []);
    p.addParamValue('minimumMagnitude', [], @isnumeric);
    p.addParamValue('maximumMagnitude', [], @isnumeric);
    p.addParamValue('minimumLatitude', [], @isnumeric);
    p.addParamValue('maximumLatitude', [], @isnumeric);
    p.addParamValue('minimumLongitude', [], @isnumeric);
    p.addParamValue('maximumLongitude', [], @isnumeric);  
    p.addParamValue('minimumDepth', [], @isnumeric);
    p.addParamValue('maximumDepth', [], @isnumeric); 
    p.addParamValue('minimumRadius', [], @isnumeric);
    p.addParamValue('maximumRadius', [], @isnumeric);     
    p.addParamValue('boxcoordinates', @isnumeric);    %[minLat, maxLat, minLon, maxLon]   % use NaN as a wildcard
    p.addParamValue('radialcoordinates', @isnumeric); % [Lat, Lon, MaxRadius, MinRadius]   % MinRadius is optional
    p.addParamValue('addarrivals', false, @islogical);
    
    % CUSTOM PARAMETERS
    p.addParamValue('subset_expression', '', @isstr);    
    p.addParamValue('subclass', '*', @ischar);
    
    p.parse(varargin{:});
    fields = fieldnames(p.Results);
    for i=1:length(fields)
        field=fields{i};
        % val = eval(sprintf('p.Results.%s;',field));
        val = p.Results.(field);
        eval(sprintf('%s = val;',field));
    end 
    
    if exist('boxcoordinates','var')
        minimumLatitude = boxcoordinates(1);
        maximumLatitude = boxcoordinates(2);
        minimumLongitude = boxcoordinates(3);
        maximumLongitude = boxcoordinates(4);            
    end
    
    if exist('radialcoordinates','var')
        centerLatitude = radialcoordinates(1);
        centerLongitude = radialcoordinates(2);
        maximumRadius = radialcoordinates(3);
        %minimumRadius = radialcoordinates(4);            
    end
    
    % Check start & end times
    snum = Catalog.read_catalog.ensure_dateformat(startTime);
    enum = Catalog.read_catalog.ensure_dateformat(endTime);

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
            if ~isempty(minimumMagnitude) & isnumeric(minimumMagnitude)
                expr = sprintf('%s && (ml >= %f || mb >= %f || ms >= %f)',expr,minimumMagnitude,minimumMagnitude,minimumMagnitude);
            end
            if ~isempty(maximumMagnitude) & isnumeric(maximumMagnitude)
                expr = sprintf('%s && (ml >= %f || mb >= %f || ms >= %f)',expr,maximumMagnitude,maximumMagnitude,maximumMagnitude);
            end
            if ~isempty(minimumLatitude) & isnumeric(minimumLatitude)
                expr = sprintf('%s && (lat >= %f)',expr, minimumLatitude);
            end
            if ~isempty(maximumLatitude) & isnumeric(maximumLatitude)
                expr = sprintf('%s && (lat <= %f)',expr, maximumLatitude);
            end            
            if ~isempty(minimumLongitude) & isnumeric(minimumLongitude)
                expr = sprintf('%s && (lon >= %f)',expr, minimumLongitude);
            end
            if ~isempty(maximumLongitude) & isnumeric(maximumLongitude)
                expr = sprintf('%s && (lon <= %f)',expr, maximumLongitude);
            end            
            if ~isempty(minimumDepth) & isnumeric(minimumDepth)
                expr = sprintf('%s && (depth >= %f)', expr,minimumDepth); 
            end
            if ~isempty(maximumDepth) & isnumeric(maximumDepth)
                expr = sprintf('%s && (depth <= %f)', expr,maximumDepth); 
            end
            if ~isempty(maximumRadius) & isnumeric(maximumRadius)
                expr = sprintf('%s && (distance(lat, lon, %f, %f) <= %f)', ...
                    expr, centerLatitude, centerLongitude, maximumRadius); 
            end            
            subset_expression = expr(4:end);
            clear expr
        end
    end

    % BUILD DBNAMELIST
    dbpathlist = {};
    
    % Loop over databases split into day, month or year volumes
    if strfindbool(dbpath, '%DD') ||  strfindbool(dbpath, '%MM') || strfindbool(dbpath, '%YYYY') % strfind returns [] if false
        if snum < enum
            for dnum=floor(snum):floor(enum-1/1440)
                dv = datevec(dnum);
                thisdb = dbpath;
                thisdb = regexprep(thisdb, '%YYYY', sprintf('%04d',dv(1)) );
                thisdb = regexprep(thisdb, '%MM', sprintf('%02d',dv(2)) );
                thisdb = regexprep(thisdb, '%DD', sprintf('%02d',dv(3)) );
                if exist(sprintf('%s.origin',thisdb),'file')
                    dbpathlist{end+1} = thisdb; % Add here
                end
            end
            dbpathlist = unique(dbpathlist);
        else
            debug.print_debug(0,'when using %YYYY, %MM or %DD in dbpath, must also specify startTime and endTime')
        end
    else
        dbpathlist = {dbpath};
    end

    if isempty(dbpathlist)
        debug.print_debug(0, 'no database found');
    end
    
    % Initialize to empty
    [lat, lon, depth, time, evid, orid, nass, mag, ml, mb, ms] = deal([]);
    [etype, auth, magtype] = deal({});

    % Loop over databases
    for dbpathitem = dbpathlist
        % Load vectors
        origins = antelope.dbgetorigins(dbpath, subset_expression)
        if length(origins.lon) == length(origins.mag)
            % Concatentate vectors
            time  = cat(1, time,  origins.time);           
            lon   = cat(1, lon,   origins.lon);
            lat   = cat(1, lat,   origins.lat);
            depth = cat(1, depth, origins.depth);
            evid  = cat(1, evid,  origins.evid);
            orid  = cat(1, orid,  origins.orid);
            nass  = cat(1, nass,  origins.nass);
            mag   = cat(1, mag,   origins.mag);
            mb   = cat(1, mb,   origins.mb);
            ml   = cat(1, ml,   origins.ml);
            ms   = cat(1, ms,   origins.ms);
            etype  = cat(1, etype, origins.etype);
            auth = cat(1,  auth, origins.auth);
            magtype = cat(1, magtype, origins.magtype);
        end
    end
    mag(mag<-3.0)=NaN; % I think Antelope uses a dummy value like -9.9
    %self = Catalog(epoch2datenum(time), lon, lat, depth, mag, magtype, etype);
    self = Catalog(time, lon, lat, depth, mag, magtype, etype);
    
    debug.printfunctionstack('<')
end


function found = strfindbool(haystack, needle)
    found = strfind(haystack, needle);
    if isempty(found)
        found = false;
    end
end
