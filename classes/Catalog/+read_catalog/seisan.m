function self = seisan(varargin)
    % READ_CATALOG.SEISAN Read a Seisan event database - consisting of
    % S-files. Gathers a list of S-files matching the request and then uses
    % the read_sfile function, to return a structure for each S-file.

    debug.printfunctionstack('>')
    
    % Process input arguments
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
    snum = read_catalog.ensure_dateformat(startTime);
    enum = read_catalog.ensure_dateformat(endTime);
    
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
    self = Catalog(dnum', lon', lat', depth', mag', magtype', etype');
    
    debug.printfunctionstack('<')
end
