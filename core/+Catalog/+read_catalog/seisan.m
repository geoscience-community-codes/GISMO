function self = seisan(varargin)
    % READ_CATALOG.SEISAN Read a Seisan event database - consisting of
    % S-files. Gathers a list of S-files matching the request and then uses
    % the read_sfile function, to return a structure for each S-file.

    debug.printfunctionstack('>')
    
    % Process input arguments
    % Process input arguments
    p = inputParser;
    p.addParameter('dbpath', '', @isstr);
    p.addParameter('startTime', -Inf);  
    p.addParameter('endTime', Inf);
%     p.addParameter('minimumMagnitude', -Inf, @isnumeric);
%     p.addParameter('maximumMagnitude', Inf, @isnumeric);
%     p.addParameter('minimumLatitude', -90., @isnumeric);
%     p.addParameter('maximumLatitude', 90., @isnumeric);
%     p.addParameter('minimumLongitude', -180., @isnumeric);
%     p.addParameter('maximumLongitude', 180., @isnumeric);  
%     p.addParameter('minimumDepth', -12, @isnumeric);
%     p.addParameter('maximumDepth', 6400., @isnumeric); 
%     p.addParameter('minimumRadius', 0., @isnumeric);
%     p.addParameter('maximumRadius', deg2km(180.0), @isnumeric); 
%     p.addParameter('boxcoordinates', [], @isnumeric);    %[minLat, maxLat, minLon, maxLon]   % use NaN as a wildcard
%     p.addParameter('radialcoordinates', [], @isnumeric); % [Lat, Lon, MaxRadius, MinRadius]   % MinRadius is optional
    p.addParameter('minimumMagnitude', NaN, @isnumeric);
    p.addParameter('maximumMagnitude', NaN, @isnumeric);
    p.addParameter('minimumLatitude', NaN, @isnumeric);
    p.addParameter('maximumLatitude', NaN, @isnumeric);
    p.addParameter('minimumLongitude', NaN, @isnumeric);
    p.addParameter('maximumLongitude', NaN, @isnumeric);  
    p.addParameter('minimumDepth', NaN, @isnumeric);
    p.addParameter('maximumDepth', NaN, @isnumeric); 
    p.addParameter('minimumRadius', NaN, @isnumeric);
    p.addParameter('maximumRadius', NaN, @isnumeric); 
    p.addParameter('boxcoordinates', [], @isnumeric);    %[minLat, maxLat, minLon, maxLon]   % use NaN as a wildcard
    p.addParameter('radialcoordinates', [], @isnumeric); % [Lat, Lon, MaxRadius, MinRadius]   % MinRadius is optional
    p.addParameter('addarrivals', false, @islogical);
    
    % CUSTOM PARAMETERS  
    p.addParameter('subclass', '*', @ischar);
    
    p.parse(varargin{:});
    fields = fieldnames(p.Results);
    for i=1:length(fields)
        field=fields{i};
        % val = eval(sprintf('p.Results.%s;',field));
        val = p.Results.(field);
        eval(sprintf('%s = val;',field));
    end 
    
    
           
    if numel(boxcoordinates)==4
        minimumLatitude = boxcoordinates(1);
        maximumLatitude = boxcoordinates(2);
        minimumLongitude = boxcoordinates(3);
        maximumLongitude = boxcoordinates(4);            
    end
    
    if numel(radialcoordinates)==4
        centerLatitude = radialcoordinates(1);
        centerLongitude = radialcoordinates(2);
        maximumRadius = radialcoordinates(3);
        %minimumRadius = radialcoordinates(4);            
    end
    
    % Check start & end times
    snum = Catalog.read_catalog.ensure_dateformat(startTime);
    enum = Catalog.read_catalog.ensure_dateformat(endTime);
    request.startTime = snum;
    request.endTime = enum;
    if ~exist(dbpath, 'dir')
        fprintf('Directory %s not found\n',dbpath);
        self = struct;
        return;
    end
    
    % get dir list of matching sfilesSfile.list_sfiles
    sfiles = Sfile.list_sfiles(dbpath, snum, enum);
    numsfiles = numel(sfiles);
    
    % loop over sfiles
    tic
    for i=1:numsfiles
        % read 
        thissfilepath = fullfile(sfiles(i).dir, sfiles(i).name);
        fprintf('Reading %4d of %4d: %s\n',i,numsfiles,thissfilepath);
        if i>1
            tav = toc/(i-1);
            tremain = (numsfiles-i)*tav;
            fprintf('Time remaining %.1f s\n',tremain);
        end
        %thiss = Sfile(thissfilepath);
        thiss = Sfile(thissfilepath, fileread(thissfilepath));
        if debug.get_debug>0
            thiss
            thiss.magnitude
        end

        % add to catalog
        dnum(i)  = thiss.otime;
        etype{i} = thiss.subclass;
        lat(i) = thiss.latitude;
        lon(i) = thiss.longitude;
        depth(i) = thiss.depth;
        wavfiles{i} = cellstr(thiss.wavfiles);
        ontime(i) = thiss.ontime;
        offtime(i) = thiss.offtime;
        sfilepath{i} = thiss.sfilepath;
        topdir{i} = thiss.topdir;
        reldir{i} = thiss.reldir;  
        aef{i} = thiss.aef;
        arrivals{i} = thiss.arrivals;
        
        % SCAFFOLD
        mag(i) = NaN;
        magtype{i} = 'u';
        try % only events with a magnitude will have this field filled out
            sfile_mags = [thiss.magnitude.value];
            if ~isempty(sfile_mags)
                [maxmag,maxmagpos]=max(sfile_mags);
                mag(i) = maxmag;
                magtype{i} = thiss.magnitude(maxmagpos).type;
            end
        end

    end
    
    if numsfiles>0
        % save request
        fields = fieldnames(p.Results);
        for i=1:length(fields)
            field=fields{i};
            eval(sprintf('request.%s = eval(field);',field));
        end 

        % create Catalog object
        self = Seisan_Catalog(dnum', lon', lat', depth', mag', magtype', etype', 'request', request, 'ontime', ontime', 'offtime', offtime');
        self.aef = aef;
        self.sfilepath = sfilepath;
        self.wavfilepath = wavfiles;
        self.topdir = topdir;
        self.reldir = reldir;
        self.arrivals = arrivals;

        filteredout = [];
        filteredin = 1:self.numberOfEvents;
        if ~isnan(request.minimumDepth)
            %filteredout = unique([find(depth<request.minimumDepth) filteredout]);
            filteredin = find(depth>=request.minimumDepth);
        end
        if ~isnan(request.maximumDepth)
            %filteredout = unique([find(depth>request.maximumDepth) filteredout]);
            filteredin = find(depth<=request.maximumDepth);
        end
        if ~isnan(request.minimumMagnitude)
            %filteredout = unique([find(mag<request.minimumMagnitude) filteredout]);
            filteredin = find(mag>=request.minimumMagnitude);
        end
        if ~isnan(request.maximumMagnitude)
            %filteredout = unique([find(mag>request.maximumMagnitude) filteredout]);   
            filteredin = find(mag<=request.maximumMagnitude);
        end
        if ~isnan(request.minimumLatitude)
            %filteredout = unique([find(lat<request.minimumLatitude) filteredout]);
            filteredin = find(lat>=request.minimumLatitude);
        end
        if ~isnan(request.maximumLatitude)
            %filteredout = unique([find(lat>request.maximumLatitude) filteredout]);
            filteredin = find(lat<=request.minimumLatitude);
        end
        if ~isnan(request.minimumLongitude)
            %filteredout = unique([find(lon<request.minimumLongitude) filteredout]);
            filteredin = find(lon>=request.minimumLongitude);
        end
        if ~isnan(request.maximumLongitude)
            %filteredout = unique([find(lon>request.maximumLongitude) filteredout]);
            filteredin = find(lon<=request.maximumLatitude);
        end
        %filteredin2 = find(~ismember(1:self.numberOfEvents,filteredout));
        self=self.subset('indices', filteredin);
        disp('min/max radius and radial coordinates not supported by Seisan reader');
    else
        self=Catalog();
        
    end
    request.dbpath = dbpath;
    self.request = request;
    debug.printfunctionstack('<')
end
