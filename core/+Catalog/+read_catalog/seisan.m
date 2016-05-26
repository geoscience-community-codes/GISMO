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
    p.addParameter('minimumMagnitude', -Inf, @isnumeric);
    p.addParameter('maximumMagnitude', Inf, @isnumeric);
    p.addParameter('minimumLatitude', -90., @isnumeric);
    p.addParameter('maximumLatitude', 90., @isnumeric);
    p.addParameter('minimumLongitude', -180., @isnumeric);
    p.addParameter('maximumLongitude', 180., @isnumeric);  
    p.addParameter('minimumDepth', -12, @isnumeric);
    p.addParameter('maximumDepth', 6400., @isnumeric); 
    p.addParameter('minimumRadius', 0., @isnumeric);
    p.addParameter('maximumRadius', deg2km(180.0), @isnumeric);     
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
    
    self.request.dbpath = dbpath;
    self.request.startTime = startTime;
    self.request.endTime = endTime;
    
%     % SCAFFOLD: might have deleted something here. These 2 lines might not
%     % be correct
%     self.request.minimumMagnitude = minimumMagnitude;
%     p.addParameter('minimumMagnitude', [], @isnumeric);
%     
%     p.addParameter('maximumMagnitude', [], @isnumeric);
%     p.addParameter('minimumLatitude', [], @isnumeric);
%     p.addParameter('maximumLatitude', [], @isnumeric);
%     p.addParameter('minimumLongitude', [], @isnumeric);
%     p.addParameter('maximumLongitude', [], @isnumeric);  
%     p.addParameter('minimumDepth', [], @isnumeric);
%     p.addParameter('maximumDepth', [], @isnumeric); 
%     p.addParameter('minimumRadius', [], @isnumeric);
%     p.addParameter('maximumRadius', [], @isnumeric);     
%     p.addParameter('boxcoordinates', @isnumeric);    %[minLat, maxLat, minLon, maxLon]   % use NaN as a wildcard
%     p.addParameter('radialcoordinates', @isnumeric); % [Lat, Lon, MaxRadius, MinRadius]   % MinRadius is optional
%     p.addParameter('addarrivals', false, @islogical);
    
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
    
    if ~exist(dbpath, 'dir')
        fprintf('Directory %s not found\n',dbpath);
        self = struct;
        return;
    end
    
    % get dir list of matching sfiles
    sfiles = Sfile.list_sfiles(dbpath, snum, enum);
    
    % loop over sfiles
    for i=1:length(sfiles)
        % read 
        fprintf('Processing %s\n',fullfile(sfiles(i).dir, sfiles(i).name));
        thiss = Sfile(fileread(fullfile(sfiles(i).dir, sfiles(i).name)));
        try
            s(i)=thiss;
        catch
            s(i)
            thiss
            error('Wrong number of fields?')
        end

        % add to catalog
        dnum(i)  = s(i).otime;
        etype{i} = s(i).subclass;
        lat(i) = s(i).latitude;
        lon(i) = s(i).longitude;
        depth(i) = s(i).depth;
        
        % SCAFFOLD
        mag(i) = NaN;
        try
            sfile_mags = [s(i).magnitude.value];
            if ~isempty(sfile_mags)
                disp('**************** ********************')
                mag(i) = max(sfile_mags);
            end
        end

        % SCAFFOLD also use durations (bbdur) and ampengfft info
        % Compute a magnitude from amp & eng, but need to know where
        % stations are. I can save these as MA and ME, to distinguish from
        % Ml, Ms, Mb, Mw if those exist
    end
    magtype = {};
    
    % save request
    fields = fieldnames(p.Results);
    for i=1:length(fields)
        field=fields{i};
        eval(sprintf('request.%s = eval(field);',field));
    end 
    
    % create Catalog object
    self = Catalog(dnum', lon', lat', depth', mag', magtype', etype', 'request', request);
    request.startTime = snum;
    request.endTime = enum;
    self.request = request;
    debug.printfunctionstack('<')
end
